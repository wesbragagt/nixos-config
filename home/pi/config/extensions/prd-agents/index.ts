import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { Type } from "@earendil-works/pi-ai";
import { defineTool, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const extensionDir = dirname(fileURLToPath(import.meta.url));
const agentsDir = join(extensionDir, "agents");

async function loadAgentPrompt(fileName: string): Promise<string> {
	return await readFile(join(agentsDir, fileName), "utf8");
}

async function runPiAgent(
	agentPrompt: string,
	task: string,
	signal: AbortSignal | undefined,
	onProgress?: (text: string) => void,
): Promise<string> {
	return await new Promise<string>((resolve, reject) => {
		const child = spawn(
			"pi",
			[
				"-p",
				"--no-session",
				"--no-extensions",
				"--no-skills",
				"--no-prompt-templates",
				"--no-themes",
				"--tools",
				"read,grep,find,ls",
				"--append-system-prompt",
				agentPrompt,
				task,
			],
			{ stdio: ["ignore", "pipe", "pipe"] },
		);

		let stdout = "";
		let stderr = "";
		let settled = false;

		const finish = (handler: () => void): void => {
			if (settled) return;
			settled = true;
			handler();
		};

		const abortHandler = (): void => {
			child.kill("SIGTERM");
			finish(() => reject(new Error("Delegated agent aborted")));
		};

		signal?.addEventListener("abort", abortHandler, { once: true });

		child.stdout.setEncoding("utf8");
		child.stderr.setEncoding("utf8");

		child.stdout.on("data", (chunk: string) => {
			stdout += chunk;
		});

		child.stderr.on("data", (chunk: string) => {
			stderr += chunk;
			const text = chunk.trim();
			if (text.length > 0) {
				onProgress?.(text);
			}
		});

		child.on("error", (error) => {
			signal?.removeEventListener("abort", abortHandler);
			finish(() => reject(error));
		});

		child.on("close", (code) => {
			signal?.removeEventListener("abort", abortHandler);

			if (code !== 0) {
				const output = stderr.trim() || stdout.trim() || `pi exited with code ${code ?? "unknown"}`;
				finish(() => reject(new Error(output)));
				return;
			}

			const result = stdout.trim();
			if (result.length === 0) {
				finish(() => reject(new Error("Delegated agent returned no output")));
				return;
			}

			finish(() => resolve(result));
		});
	});
}

const plannerAgentTool = defineTool({
	name: "planner_agent",
	label: "Planner Agent",
	description: "Delegate PRD drafting to the planner agent",
	promptSnippet: "Draft a PRD with the planner agent in an isolated read-only run",
	promptGuidelines: [
		"Use planner_agent when creating or refining a PRD before writing prd.md.",
	],
	parameters: Type.Object({
		task: Type.String({ description: "The planning task for the planner agent" }),
	}),
	async execute(_toolCallId, params, signal, onUpdate) {
		onUpdate?.({ content: [{ type: "text", text: "Delegating to planner agent..." }] });
		const agentPrompt = await loadAgentPrompt("planner.md");
		const result = await runPiAgent(agentPrompt, params.task, signal, (text) => {
			onUpdate?.({ content: [{ type: "text", text }] });
		});
		return {
			content: [{ type: "text", text: result }],
			details: { agent: "planner" },
		};
	},
});

const taskBreakdownAgentTool = defineTool({
	name: "task_breakdown_agent",
	label: "Task Breakdown Agent",
	description: "Delegate task planning to the task breakdown agent",
	promptSnippet: "Turn a PRD into tasks.yaml and detail file drafts with the task breakdown agent",
	promptGuidelines: [
		"Use task_breakdown_agent after a PRD exists to produce tasks.yaml and per-task detail files.",
	],
	parameters: Type.Object({
		task: Type.String({ description: "The task breakdown request for the delegated agent" }),
	}),
	async execute(_toolCallId, params, signal, onUpdate) {
		onUpdate?.({ content: [{ type: "text", text: "Delegating to task breakdown agent..." }] });
		const agentPrompt = await loadAgentPrompt("task-breakdown.md");
		const result = await runPiAgent(agentPrompt, params.task, signal, (text) => {
			onUpdate?.({ content: [{ type: "text", text }] });
		});
		return {
			content: [{ type: "text", text: result }],
			details: { agent: "task-breakdown" },
		};
	},
});

export default function prdAgentsExtension(pi: ExtensionAPI): void {
	pi.registerTool(plannerAgentTool);
	pi.registerTool(taskBreakdownAgentTool);
}
