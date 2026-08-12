/**
 * Tmux window spawner adapter.
 *
 * Creates a new tmux window for each subagent running pi in interactive mode.
 * The user can switch to the window, watch the TUI, type prompts, steer,
 * answer clarifying questions, etc.
 *
 * Completion is signaled when pi exits (Ctrl+D / Ctrl+C). The wrapper
 * script then extracts the last assistant message from the session file
 * and writes it to a sentinel file for the parent agent to read.
 *
 * Falls back gracefully when not running inside tmux (isAvailable = false).
 */

import { execSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { ProcessSpawner, SpawnOptions, SpawnResult } from "../ports/process-spawner.port.js";

function sleep(ms: number): Promise<void> {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

function fileExists(filePath: string): boolean {
	try {
		fs.accessSync(filePath);
		return true;
	} catch {
		return false;
	}
}

function readTextFile(filePath: string): string {
	try {
		return fs.readFileSync(filePath, "utf-8");
	} catch {
		return "";
	}
}

export class TmuxSpawnerAdapter implements ProcessSpawner {
	private readonly extractScriptPath: string;

	constructor(private readonly extensionDir: string) {
		this.extractScriptPath = path.join(extensionDir, "bin", "extract-output.js");
	}

	get displayName(): string {
		return "tmux";
	}

	get isAvailable(): boolean {
		return Boolean(process.env.TMUX) && this.tmuxIsReachable();
	}

	async spawn(options: SpawnOptions): Promise<SpawnResult> {
		const tmpDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-subagent-"));
		const sessionDir = path.join(tmpDir, "sessions");

		try {
			const windowId = this.createWindow(options, tmpDir, sessionDir);
			this.sendInitialPrompt(windowId, options.promptText);
			return await this.waitForCompletion(options, tmpDir, windowId);
		} finally {
			this.cleanupDir(tmpDir);
		}
	}

	private tmuxIsReachable(): boolean {
		try {
			execSync("tmux list-sessions 2>/dev/null", { stdio: "ignore" });
			return true;
		} catch {
			return false;
		}
	}

	private createWindow(options: SpawnOptions, tmpDir: string, sessionDir: string): string {
		const runnerPath = this.writeRunnerScript(options, tmpDir, sessionDir);

		try {
			const windowId = execSync(
				`tmux new-window -d -P -F "#{window_id}" -n ${JSON.stringify(options.windowName)} -- ${JSON.stringify(runnerPath)}`,
				{ encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] },
			).trim();

			if (!windowId) {
				throw new Error("tmux new-window returned empty window ID");
			}

			return windowId;
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			throw new Error(`Failed to create tmux window: ${message}`);
		}
	}

	private writeRunnerScript(options: SpawnOptions, tmpDir: string, sessionDir: string): string {
		const runnerPath = path.join(tmpDir, "runner.sh");

		// Build pi flags (no --mode json, no -p — fully interactive)
		const piFlags = [...options.args];
		piFlags.push("--session-dir", sessionDir);

		const piInvocation = [options.command, ...piFlags]
			.map((arg) => JSON.stringify(arg))
			.join(" ");

		const content = [
			"#!/bin/bash",
			`SESSION_DIR=${JSON.stringify(sessionDir)}`,
			`EXTRACT_SCRIPT=${JSON.stringify(this.extractScriptPath)}`,
			`DONE_FILE=${JSON.stringify(path.join(tmpDir, "done"))}`,
			`OUTPUT_FILE=${JSON.stringify(path.join(tmpDir, "output"))}`,
			`EXIT_FILE=${JSON.stringify(path.join(tmpDir, "exit"))}`,
			`STDERR_FILE=${JSON.stringify(path.join(tmpDir, "stderr"))}`,
			"",
			`mkdir -p "$SESSION_DIR"`,
			"",
			// Run pi interactively — user has full TUI access
			`${piInvocation} 2>"$STDERR_FILE"`,
			`PI_EXIT=$?`,
			"",
			// Extract last assistant text from session file
			`OUTPUT=$("$EXTRACT_SCRIPT" "$SESSION_DIR" 2>/dev/null || echo "")`,
			`echo -n "$OUTPUT" > "$OUTPUT_FILE"`,
			`echo "$PI_EXIT" > "$EXIT_FILE"`,
			`touch "$DONE_FILE"`,
			"",
		].join("\n");

		fs.writeFileSync(runnerPath, content, { mode: 0o755 });
		return runnerPath;
	}

	private sendInitialPrompt(windowId: string, promptText: string): void {
		// Wait briefly for pi's TUI to initialize before sending keys
		const delay = 1500;
		const escapedPrompt = promptText
			.replace(/\\/g, "\\\\")
			.replace(/"/g, '\\"');

		try {
			execSync(`sleep ${delay / 1000} && tmux send-keys -t ${JSON.stringify(windowId)} ${JSON.stringify(escapedPrompt)} Enter`, {
				stdio: "ignore",
			});
		} catch {
			// If send-keys fails, the user can still type manually
		}
	}

	private async waitForCompletion(
		options: SpawnOptions,
		tmpDir: string,
		windowId: string,
	): Promise<SpawnResult> {
		const startTime = Date.now();
		const donePath = path.join(tmpDir, "done");
		const outputPath = path.join(tmpDir, "output");
		const stderrPath = path.join(tmpDir, "stderr");
		const exitPath = path.join(tmpDir, "exit");

		while (true) {
			if (options.signal?.aborted) {
				this.sendKeys(windowId, "C-c");
				throw new Error("Subagent aborted");
			}

			if (!this.windowExists(windowId)) {
				// Window was killed externally — try to read whatever output we have
				return this.collectResult(startTime, outputPath, stderrPath, exitPath, windowId);
			}

			if (fileExists(donePath)) {
				return this.collectResult(startTime, outputPath, stderrPath, exitPath, windowId);
			}

			await sleep(1000);
		}
	}

	private collectResult(
		startTime: number,
		outputPath: string,
		stderrPath: string,
		exitPath: string,
		windowId: string,
	): SpawnResult {
		const rawOutput = readTextFile(outputPath);
		const stderr = readTextFile(stderrPath);
		const exitCode = parseInt(readTextFile(exitPath), 10) || 0;

		return {
			rawOutput,
			stderr,
			exitCode,
			windowId,
			durationMs: Date.now() - startTime,
		};
	}

	private sendKeys(windowId: string, keys: string): void {
		try {
			execSync(`tmux send-keys -t ${JSON.stringify(windowId)} ${keys}`, { stdio: "ignore" });
		} catch {
			// window may already be gone
		}
	}

	private windowExists(windowId: string): boolean {
		try {
			const output = execSync(
				`tmux list-windows -t ${JSON.stringify(windowId)} -F "#{window_id}" 2>/dev/null`,
				{ encoding: "utf-8" },
			);
			return output.trim().length > 0;
		} catch {
			return false;
		}
	}

	private cleanupDir(tmpDir: string): void {
		try {
			fs.rmSync(tmpDir, { recursive: true, force: true });
		} catch {
			// best-effort cleanup
		}
	}
}
