/**
 * Tmux Subagent Extension — Composition Root
 *
 * Wires domain entities, port interfaces, and framework adapters together.
 * This is the ONLY file that imports from @earendil-works/pi-coding-agent
 * and knows about the pi event system.
 *
 * When running inside tmux, subagents are dispatched in visible tmux windows.
 * When not in tmux, falls back to background subprocess execution.
 */

import { fileURLToPath } from "node:url";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@earendil-works/pi-ai";
import { Container, Markdown, Spacer, Text } from "@earendil-works/pi-tui";

// Domain
import type { AgentScope, DispatchMode, DispatchDetails, SubagentResult } from "./domain/types.js";

// Adapters
import { AgentDiscoveryAdapter } from "./adapters/agent-discovery.adapter.js";
import { TmuxSpawnerAdapter } from "./adapters/tmux-spawner.adapter.js";
import { SubprocessSpawnerAdapter } from "./adapters/subprocess-spawner.adapter.js";

// Application
import { SubagentApp } from "./application/subagent.app.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const extensionDir = __dirname;

const AgentScopeSchema = StringEnum(["user", "project", "both"] as const, {
	description: 'Which agent directories to use. Default: "user".',
	default: "user",
});

const TaskItemSchema = Type.Object({
	agent: Type.String({ description: "Name of the agent to invoke" }),
	task: Type.String({ description: "Task to delegate to the agent" }),
	cwd: Type.Optional(Type.String({ description: "Working directory for the agent process" })),
});

const SubagentParams = Type.Object({
	agent: Type.Optional(Type.String({ description: "Name of the agent (single mode)" })),
	task: Type.Optional(Type.String({ description: "Task to delegate (single mode)" })),
	tasks: Type.Optional(Type.Array(TaskItemSchema, { description: "Array of {agent, task} for parallel execution" })),
	chain: Type.Optional(Type.Array(TaskItemSchema, { description: "Array of {agent, task} for chain execution" })),
	agentScope: Type.Optional(AgentScopeSchema),
	confirmProjectAgents: Type.Optional(
		Type.Boolean({ description: "Prompt before running project-local agents. Default: true.", default: true }),
	),
	cwd: Type.Optional(Type.String({ description: "Working directory (single mode)" })),
});

export default function tmuxSubagentExtension(pi: ExtensionAPI): void {
	// ─── Adapters ──────────────────────────────────────────────
	const discoverer = new AgentDiscoveryAdapter();
	const tmuxSpawner = new TmuxSpawnerAdapter(extensionDir);
	const subprocessSpawner = new SubprocessSpawnerAdapter();

	// ─── Application ───────────────────────────────────────────
	const app = new SubagentApp(discoverer, tmuxSpawner.isAvailable ? tmuxSpawner : subprocessSpawner);

	// ─── Register Tool ─────────────────────────────────────────
	pi.registerTool({
		name: "tmux-subagent",
		label: "Tmux Subagent",
		description: [
			"Delegate tasks to specialized subagents. When running inside tmux, each subagent gets its own visible tmux window.",
			"Modes: single (agent + task), parallel (tasks array), chain (sequential with {previous} placeholder).",
			'Default agent scope is "user" (from ~/.pi/agent/agents).',
		].join(" "),
		parameters: SubagentParams,

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const agentScope: AgentScope = params.agentScope ?? "user";
			const discovery = app.discoverAgents(ctx.cwd, agentScope);
			const confirmProjectAgents = params.confirmProjectAgents ?? true;

			const hasChain = (params.chain?.length ?? 0) > 0;
			const hasTasks = (params.tasks?.length ?? 0) > 0;
			const hasSingle = Boolean(params.agent && params.task);
			const modeCount = Number(hasChain) + Number(hasTasks) + Number(hasSingle);

			const makeDetails = (mode: DispatchMode, results: readonly SubagentResult[]): DispatchDetails => ({
				mode,
				agentScope,
				results,
				inTmux: app.isTmuxAvailable,
			});

			if (modeCount !== 1) {
				const available = discovery.agents.map((a) => `${a.name} (${a.source})`).join(", ") || "none";
				return {
					content: [{ type: "text", text: `Invalid parameters. Provide exactly one mode.\nAvailable agents: ${available}` }],
					details: makeDetails("single", []),
				};
			}

			// Confirm project-local agents
			if ((agentScope === "project" || agentScope === "both") && confirmProjectAgents && ctx.hasUI) {
				const requestedNames = new Set<string>();
				if (params.chain) for (const step of params.chain) requestedNames.add(step.agent);
				if (params.tasks) for (const t of params.tasks) requestedNames.add(t.agent);
				if (params.agent) requestedNames.add(params.agent);

				const projectAgents = Array.from(requestedNames)
					.map((name) => discovery.agents.find((a) => a.name === name))
					.filter((a): a is NonNullable<typeof a> => a?.source === "project");

				if (projectAgents.length > 0) {
					const names = projectAgents.map((a) => a.name).join(", ");
					const dir = discovery.projectAgentsDir ?? "(unknown)";
					const ok = await ctx.ui.confirm(
						"Run project-local agents?",
						`Agents: ${names}\nSource: ${dir}\n\nProject agents are repo-controlled. Only continue for trusted repositories.`,
					);
					if (!ok) {
						return {
							content: [{ type: "text", text: "Canceled: project-local agents not approved." }],
							details: makeDetails(hasChain ? "chain" : hasTasks ? "parallel" : "single", []),
						};
					}
				}
			}

			// ─── Chain mode ─────────────────────────────────────
			if (params.chain && params.chain.length > 0) {
				const { results, stopped } = await app.dispatchChain({
					agents: discovery.agents,
					chain: params.chain,
					cwd: ctx.cwd,
					signal,
				});

				if (stopped) {
					const last = results[results.length - 1];
					return {
						content: [{ type: "text", text: last.output }],
						details: makeDetails("chain", results),
						isError: true,
					};
				}

				const finalOutput = results[results.length - 1]?.output ?? "(no output)";
				return {
					content: [{ type: "text", text: finalOutput }],
					details: makeDetails("chain", results),
				};
			}

			// ─── Parallel mode ──────────────────────────────────
			if (params.tasks && params.tasks.length > 0) {
				const results = await app.dispatchParallel({
					agents: discovery.agents,
					tasks: params.tasks,
					cwd: ctx.cwd,
					signal,
				});

				const successCount = results.filter((r) => r.success).length;
				const summaries = results.map((r) => {
					const preview = r.output.length > 100 ? `${r.output.slice(0, 100)}...` : r.output;
					return `[${r.agent}] ${r.success ? "completed" : "failed"}: ${preview || "(no output)"}`;
				});

				return {
					content: [
						{ type: "text", text: `Parallel: ${successCount}/${results.length} succeeded\n\n${summaries.join("\n\n")}` },
					],
					details: makeDetails("parallel", results),
				};
			}

			// ─── Single mode ────────────────────────────────────
			if (params.agent && params.task) {
				const result = await app.dispatchSingle({
					agents: discovery.agents,
					agentName: params.agent,
					task: params.task,
					cwd: params.cwd ?? ctx.cwd,
					signal,
				});

				return {
					content: [{ type: "text", text: result.output }],
					details: makeDetails("single", [result]),
					isError: !result.success,
				};
			}

			const available = discovery.agents.map((a) => `${a.name} (${a.source})`).join(", ") || "none";
			return {
				content: [{ type: "text", text: `Invalid parameters. Available agents: ${available}` }],
				details: makeDetails("single", []),
			};
		},

		// ─── Rendering ──────────────────────────────────────────
		renderCall(args, theme, _context) {
			const scope: AgentScope = args.agentScope ?? "user";
			const tmuxBadge = app.isTmuxAvailable ? theme.fg("success", " tmux") : theme.fg("muted", " bg");

			if (args.chain && args.chain.length > 0) {
				let text =
					theme.fg("toolTitle", theme.bold("tmux-subagent ")) +
					theme.fg("accent", `chain (${args.chain.length} steps)`) +
					theme.fg("muted", ` [${scope}]`) +
					tmuxBadge;
				for (let i = 0; i < Math.min(args.chain.length, 3); i++) {
					const step = args.chain[i];
					const cleanTask = step.task.replace(/\{previous\}/g, "").trim();
					const preview = cleanTask.length > 40 ? `${cleanTask.slice(0, 40)}...` : cleanTask;
					text += "\n  " + theme.fg("muted", `${i + 1}.`) + " " + theme.fg("accent", step.agent) + theme.fg("dim", ` ${preview}`);
				}
				if (args.chain.length > 3) text += `\n  ${theme.fg("muted", `... +${args.chain.length - 3} more`)}`;
				return new Text(text, 0, 0);
			}

			if (args.tasks && args.tasks.length > 0) {
				let text =
					theme.fg("toolTitle", theme.bold("tmux-subagent ")) +
					theme.fg("accent", `parallel (${args.tasks.length} tasks)`) +
					theme.fg("muted", ` [${scope}]`) +
					tmuxBadge;
				for (const t of args.tasks.slice(0, 3)) {
					const preview = t.task.length > 40 ? `${t.task.slice(0, 40)}...` : t.task;
					text += `\n  ${theme.fg("accent", t.agent)}${theme.fg("dim", ` ${preview}`)}`;
				}
				if (args.tasks.length > 3) text += `\n  ${theme.fg("muted", `... +${args.tasks.length - 3} more`)}`;
				return new Text(text, 0, 0);
			}

			const agentName = args.agent || "...";
			const preview = args.task ? (args.task.length > 60 ? `${args.task.slice(0, 60)}...` : args.task) : "...";
			let text =
				theme.fg("toolTitle", theme.bold("tmux-subagent ")) +
				theme.fg("accent", agentName) +
				theme.fg("muted", ` [${scope}]`) +
				tmuxBadge;
			text += `\n  ${theme.fg("dim", preview)}`;
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme, _context) {
			const details = result.details as DispatchDetails | undefined;
			if (!details || details.results.length === 0) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "(no output)", 0, 0);
			}

			return renderResults(details.results, details.mode, expanded, details.inTmux, theme);
		},
	});

	// ─── Commands ─────────────────────────────────────────────
	pi.registerCommand("agents", {
		description: "List available subagent definitions",
		handler: async (_args, ctx) => {
			const discovery = app.discoverAgents(ctx.cwd, "both");
			if (discovery.agents.length === 0) {
				ctx.ui.notify("No agents found in ~/.pi/agent/agents/ or .pi/agents/", "info");
				return;
			}

			const lines = discovery.agents.map((a) => {
				const meta = [a.model ? `model: ${a.model}` : null, a.tools ? `tools: ${a.tools.join(",")}` : null]
					.filter(Boolean)
					.join(", ");
				return `${a.name} (${a.source})${meta ? ` — ${meta}` : ""}\n  ${a.description}`;
			});

			ctx.ui.notify(`Agents:\n${lines.join("\n\n")}`, "info");
		},
	});
}

// ─── Shared rendering helpers ────────────────────────────────

function formatDuration(ms: number): string {
	if (ms < 1000) return `${ms}ms`;
	return `${(ms / 1000).toFixed(1)}s`;
}

function renderResults(
	results: readonly SubagentResult[],
	mode: DispatchMode,
	expanded: boolean,
	inTmux: boolean,
	theme: { fg: (color: string, text: string) => string; bold: (text: string) => string; dim: (text: string) => string },
): Text | Container {
	if (mode === "single" && results.length === 1) {
		return renderSingleResult(results[0], expanded, inTmux, theme);
	}

	if (mode === "chain") {
		return renderChainResults(results, expanded, inTmux, theme);
	}

	return renderParallelResults(results, expanded, inTmux, theme);
}

function renderSingleResult(
	r: SubagentResult,
	expanded: boolean,
	inTmux: boolean,
	theme: { fg: (color: string, text: string) => string; bold: (text: string) => string; dim: (text: string) => string },
): Text | Container {
	const icon = r.success ? theme.fg("success", "✓") : theme.fg("error", "✗");
	const tmuxInfo = r.tmuxWindowId ? theme.fg("dim", ` (tmux ${r.tmuxWindowId})`) : "";
	const duration = theme.fg("dim", ` ${formatDuration(r.durationMs)}`);

	if (expanded) {
		const container = new Container();
		let header = `${icon} ${theme.fg("toolTitle", theme.bold(r.agent))}${theme.fg("muted", ` (${r.agentSource})`)}${tmuxInfo}${duration}`;
		container.addChild(new Text(header, 0, 0));
		container.addChild(new Spacer(1));
		container.addChild(new Text(theme.fg("muted", "─── Task ───"), 0, 0));
		container.addChild(new Text(theme.fg("dim", r.task), 0, 0));
		container.addChild(new Spacer(1));
		container.addChild(new Text(theme.fg("muted", "─── Output ───"), 0, 0));
		container.addChild(new Markdown(r.output.trim(), 0, 0, getMarkdownTheme()));
		return container;
	}

	let text = `${icon} ${theme.fg("toolTitle", theme.bold(r.agent))}${theme.fg("muted", ` (${r.agentSource})`)}${tmuxInfo}${duration}`;
	const preview = r.output.length > 200 ? `${r.output.slice(0, 200)}...` : r.output;
	if (preview) text += `\n${theme.fg("dim", preview)}`;
	return new Text(text, 0, 0);
}

function renderChainResults(
	results: readonly SubagentResult[],
	expanded: boolean,
	inTmux: boolean,
	theme: { fg: (color: string, text: string) => string; bold: (text: string) => string; dim: (text: string) => string },
): Text | Container {
	const successCount = results.filter((r) => r.success).length;
	const icon = successCount === results.length ? theme.fg("success", "✓") : theme.fg("error", "✗");

	if (expanded) {
		const container = new Container();
		container.addChild(
			new Text(
				`${icon} ${theme.fg("toolTitle", theme.bold("chain "))}${theme.fg("accent", `${successCount}/${results.length} steps`)}${inTmux ? theme.fg("dim", " (tmux)") : ""}`,
				0,
				0,
			),
		);

		for (let i = 0; i < results.length; i++) {
			const r = results[i];
			const rIcon = r.success ? theme.fg("success", "✓") : theme.fg("error", "✗");
			const tmuxInfo = r.tmuxWindowId ? theme.fg("dim", ` (tmux ${r.tmuxWindowId})`) : "";
			container.addChild(new Spacer(1));
			container.addChild(new Text(`${theme.fg("muted", `─── Step ${i + 1}: `)}${theme.fg("accent", r.agent)} ${rIcon}${tmuxInfo}${theme.fg("dim", ` ${formatDuration(r.durationMs)}`)}`, 0, 0));
			container.addChild(new Text(theme.fg("dim", r.task), 0, 0));
			container.addChild(new Markdown(r.output.trim(), 0, 0, getMarkdownTheme()));
		}

		return container;
	}

	let text = `${icon} ${theme.fg("toolTitle", theme.bold("chain "))}${theme.fg("accent", `${successCount}/${results.length} steps`)}${inTmux ? theme.fg("dim", " (tmux)") : ""}`;
	for (let i = 0; i < results.length; i++) {
		const r = results[i];
		const rIcon = r.success ? theme.fg("success", "✓") : theme.fg("error", "✗");
		const preview = r.output.length > 100 ? `${r.output.slice(0, 100)}...` : r.output;
		text += `\n\n${theme.fg("muted", `${i + 1}.`)} ${theme.fg("accent", r.agent)} ${rIcon}${theme.fg("dim", ` — ${preview || "(no output)"}`)}`;
	}
	return new Text(text, 0, 0);
}

function renderParallelResults(
	results: readonly SubagentResult[],
	expanded: boolean,
	inTmux: boolean,
	theme: { fg: (color: string, text: string) => string; bold: (text: string) => string; dim: (text: string) => string },
): Text | Container {
	const successCount = results.filter((r) => r.success).length;
	const icon = successCount === results.length ? theme.fg("success", "✓") : theme.fg("warning", "◐");

	if (expanded) {
		const container = new Container();
		container.addChild(
			new Text(
				`${icon} ${theme.fg("toolTitle", theme.bold("parallel "))}${theme.fg("accent", `${successCount}/${results.length} tasks`)}${inTmux ? theme.fg("dim", " (tmux)") : ""}`,
				0,
				0,
			),
		);

		for (const r of results) {
			const rIcon = r.success ? theme.fg("success", "✓") : theme.fg("error", "✗");
			const tmuxInfo = r.tmuxWindowId ? theme.fg("dim", ` (tmux ${r.tmuxWindowId})`) : "";
			container.addChild(new Spacer(1));
			container.addChild(new Text(`${theme.fg("muted", "─── ")}${theme.fg("accent", r.agent)} ${rIcon}${tmuxInfo}${theme.fg("dim", ` ${formatDuration(r.durationMs)}`)}`, 0, 0));
			container.addChild(new Text(theme.fg("dim", r.task), 0, 0));
			container.addChild(new Markdown(r.output.trim(), 0, 0, getMarkdownTheme()));
		}

		return container;
	}

	let text = `${icon} ${theme.fg("toolTitle", theme.bold("parallel "))}${theme.fg("accent", `${successCount}/${results.length} tasks`)}${inTmux ? theme.fg("dim", " (tmux)") : ""}`;
	for (const r of results) {
		const rIcon = r.success ? theme.fg("success", "✓") : theme.fg("error", "✗");
		const preview = r.output.length > 100 ? `${r.output.slice(0, 100)}...` : r.output;
		text += `\n\n${theme.fg("muted", "─── ")}${theme.fg("accent", r.agent)} ${rIcon}${theme.fg("dim", ` — ${preview || "(no output)"}`)}`;
	}
	return new Text(text, 0, 0);
}
