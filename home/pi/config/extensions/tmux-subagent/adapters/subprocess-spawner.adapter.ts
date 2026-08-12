/**
 * Subprocess spawner adapter (fallback when not in tmux).
 *
 * Spawns pi as a direct child process in --mode json for structured output.
 * This is the non-interactive fallback — no tmux window, no user interaction.
 */

import { spawn } from "node:child_process";
import type { ProcessSpawner, SpawnOptions, SpawnResult } from "../ports/process-spawner.port.js";

export class SubprocessSpawnerAdapter implements ProcessSpawner {
	get displayName(): string {
		return "subprocess";
	}

	get isAvailable(): boolean {
		return true;
	}

	async spawn(options: SpawnOptions): Promise<SpawnResult> {
		const startTime = Date.now();
		let wasAborted = false;

		// Fallback uses --mode json -p for structured output (non-interactive)
		const args = [
			"--mode", "json", "-p", "--no-session",
			...options.args,
			options.promptText,
		];

		const rawOutput = await new Promise<string>((resolve, reject) => {
			const proc = spawn(options.command, args, {
				cwd: options.cwd,
				shell: false,
				stdio: ["ignore", "pipe", "pipe"],
			});

			let stdoutBuffer = "";
			let stderrBuffer = "";

			proc.stdout.on("data", (data: Buffer) => {
				stdoutBuffer += data.toString();
			});

			proc.stderr.on("data", (data: Buffer) => {
				stderrBuffer += data.toString();
			});

			proc.on("close", (code) => {
				if (wasAborted) {
					reject(new Error("Subagent aborted"));
					return;
				}
				resolve(stdoutBuffer);
			});

			proc.on("error", (error) => {
				reject(new Error(`Failed to spawn subagent: ${error.message}`));
			});

			if (options.signal) {
				const abortHandler = () => {
					wasAborted = true;
					proc.kill("SIGTERM");
					setTimeout(() => {
						if (!proc.killed) proc.kill("SIGKILL");
					}, 5000);
				};
				if (options.signal.aborted) abortHandler();
				else options.signal.addEventListener("abort", abortHandler, { once: true });
			}
		});

		return {
			rawOutput,
			stderr: "",
			exitCode: 0,
			windowId: undefined,
			durationMs: Date.now() - startTime,
		};
	}
}
