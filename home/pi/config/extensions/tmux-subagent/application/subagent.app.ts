/**
 * Subagent application layer.
 *
 * Orchestrates single, parallel, and chain dispatch modes.
 * Builds pi invocation arguments and delegates process spawning
 * to the ProcessSpawner port.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import type { AgentConfig, AgentScope, SubagentResult, TaskItem } from "../domain/types.js";
import type { ProcessSpawner } from "../ports/process-spawner.port.js";

const MAX_PARALLEL_TASKS = 8;
const MAX_CONCURRENCY = 4;

export function getFinalOutput(rawOutput: string): string {
	if (!rawOutput.trim()) return "";

	// Detect mode: if the first non-empty line parses as JSON, treat as JSONL
	const firstLine = rawOutput.split("\n").find((l) => l.trim());
	if (!firstLine) return "";

	try {
		JSON.parse(firstLine);
	} catch {
		// Not JSON — plain text from tmux session extraction
		return rawOutput;
	}

	// JSONL mode: extract last assistant message_end text
	let lastText = "";
	for (const line of rawOutput.split("\n")) {
		if (!line.trim()) continue;
		try {
			const event = JSON.parse(line);
			if (event.type === "message_end" && event.message?.role === "assistant") {
				for (const part of event.message.content || []) {
					if (part.type === "text" && part.text) {
						lastText = part.text;
					}
				}
			}
		} catch {
			// skip malformed lines in JSONL
		}
	}

	return lastText;
}

function getExitStatusFromJson(rawOutput: string): { stopReason?: string; errorMessage?: string } {
	for (const line of rawOutput.split("\n")) {
		if (!line.trim()) continue;
		try {
			const event = JSON.parse(line);
			if (event.type === "message_end" && event.message?.role === "assistant") {
				return {
					stopReason: event.message.stopReason ? String(event.message.stopReason) : undefined,
					errorMessage: event.message.errorMessage ? String(event.message.errorMessage) : undefined,
				};
			}
		} catch {
			// skip
		}
	}
	return {};
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");

	if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}

	const execName = path.basename(process.execPath).toLowerCase();
	const isGenericRuntime = /^(node|bun)(\.exe)?$/.test(execName);

	if (!isGenericRuntime) {
		return { command: process.execPath, args };
	}

	return { command: "pi", args };
}

export class SubagentApp {
	constructor(
		private readonly discoverer: {
			discover(cwd: string, scope: AgentScope): { agents: readonly AgentConfig[]; projectAgentsDir: string | null };
		},
		private readonly spawner: ProcessSpawner,
	) {}

	get isTmuxAvailable(): boolean {
		return this.spawner.isAvailable && this.spawner.displayName === "tmux";
	}

	discoverAgents(cwd: string, scope: AgentScope) {
		return this.discoverer.discover(cwd, scope);
	}

	async dispatchSingle(options: {
		agents: readonly AgentConfig[];
		agentName: string;
		task: string;
		cwd: string;
		signal?: AbortSignal;
	}): Promise<SubagentResult> {
		const { agents, agentName, task, cwd, signal } = options;
		const agent = agents.find((a) => a.name === agentName);

		if (!agent) {
			return {
				agent: agentName,
				agentSource: "unknown",
				task,
				success: false,
				output: `Unknown agent: "${agentName}". Available: ${agents.map((a) => `"${a.name}"`).join(", ") || "none"}.`,
				stderr: "",
				exitCode: 1,
				tmuxWindowId: undefined,
				durationMs: 0,
			};
		}

		const { command, args, cleanup } = this.buildPiArgs(agent, task);
		try {
			const result = await this.spawner.spawn({
				command,
				args,
				cwd,
				windowName: `sa:${agent.name}`,
				promptText: `Task: ${task}`,
				signal,
			});
			cleanup();

			const output = getFinalOutput(result.rawOutput);
			const isJson = result.rawOutput.trimStart().startsWith("{");
			const status = isJson ? getExitStatusFromJson(result.rawOutput) : {};
			const isError = result.exitCode !== 0 || status.stopReason === "error" || status.stopReason === "aborted";
			const errorMsg = status.errorMessage || result.stderr || output;

			return {
				agent: agent.name,
				agentSource: agent.source,
				task,
				success: !isError,
				output: isError ? `Agent ${status.stopReason || "failed"}: ${errorMsg}` : output,
				stderr: result.stderr,
				exitCode: result.exitCode,
				tmuxWindowId: result.windowId,
				durationMs: result.durationMs,
			};
		} catch (error) {
			cleanup();
			const message = error instanceof Error ? error.message : String(error);
			return {
				agent: agent.name,
				agentSource: agent.source,
				task,
				success: false,
				output: `Subagent error: ${message}`,
				stderr: message,
				exitCode: 1,
				tmuxWindowId: undefined,
				durationMs: 0,
			};
		}
	}

	async dispatchParallel(options: {
		agents: readonly AgentConfig[];
		tasks: readonly TaskItem[];
		cwd: string;
		signal?: AbortSignal;
	}): Promise<SubagentResult[]> {
		const { agents, tasks, cwd, signal } = options;

		if (tasks.length > MAX_PARALLEL_TASKS) {
			return [
				{
					agent: "parallel",
					agentSource: "unknown",
					task: `(${tasks.length} tasks)`,
					success: false,
					output: `Too many parallel tasks (${tasks.length}). Max is ${MAX_PARALLEL_TASKS}.`,
					stderr: "",
					exitCode: 1,
					tmuxWindowId: undefined,
					durationMs: 0,
				},
			];
		}

		return mapWithConcurrencyLimit(tasks, MAX_CONCURRENCY, async (t) => {
			return await this.dispatchSingle({
				agents,
				agentName: t.agent,
				task: t.task,
				cwd: t.cwd ?? cwd,
				signal,
			});
		});
	}

	async dispatchChain(options: {
		agents: readonly AgentConfig[];
		chain: readonly TaskItem[];
		cwd: string;
		signal?: AbortSignal;
	}): Promise<{ results: SubagentResult[]; stopped: boolean }> {
		const { agents, chain, cwd, signal } = options;
		const results: SubagentResult[] = [];
		let previousOutput = "";

		for (let i = 0; i < chain.length; i++) {
			const step = chain[i];
			const taskWithContext = step.task.replace(/\{previous\}/g, previousOutput);

			const result = await this.dispatchSingle({
				agents,
				agentName: step.agent,
				task: taskWithContext,
				cwd: step.cwd ?? cwd,
				signal,
			});
			results.push(result);

			if (!result.success) {
				return { results, stopped: true };
			}

			previousOutput = result.output;
		}

		return { results, stopped: false };
	}

	buildPiArgs(agent: AgentConfig, _task: string): { command: string; args: string[]; cleanup: () => void } {
		// Build pi flags only — no --mode, no -p, no prompt text.
		// The tmux adapter runs pi interactively and sends the prompt via send-keys.
		// The subprocess fallback adds --mode json -p itself.
		const baseArgs: string[] = [];

		if (agent.tools && agent.tools.length > 0) baseArgs.push("--tools", agent.tools.join(","));

		let tmpDir: string | null = null;
		let tmpPath: string | null = null;

		if (agent.systemPrompt.trim()) {
			tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "pi-subagent-prompt-"));
			const safeName = agent.name.replace(/[^\w.-]+/g, "_");
			tmpPath = path.join(tmpDir, `prompt-${safeName}.md`);
			fs.writeFileSync(tmpPath, agent.systemPrompt, { encoding: "utf-8", mode: 0o600 });
			baseArgs.push("--append-system-prompt", tmpPath);
		}

		const invocation = getPiInvocation(baseArgs);

		return {
			command: invocation.command,
			args: invocation.args,
			cleanup: () => {
				if (tmpPath) {
					try { fs.unlinkSync(tmpPath); } catch { /* ignore */ }
				}
				if (tmpDir) {
					try { fs.rmdirSync(tmpDir); } catch { /* ignore */ }
				}
			},
		};
	}
}

async function mapWithConcurrencyLimit<TIn, TOut>(
	items: readonly TIn[],
	concurrency: number,
	fn: (item: TIn) => Promise<TOut>,
): Promise<TOut[]> {
	if (items.length === 0) return [];
	const limit = Math.max(1, Math.min(concurrency, items.length));
	const results = new Array<TOut>(items.length);
	let nextIndex = 0;

	const workers = Array.from({ length: limit }, async () => {
		while (true) {
			const current = nextIndex++;
			if (current >= items.length) return;
			results[current] = await fn(items[current]);
		}
	});

	await Promise.all(workers);
	return results;
}
