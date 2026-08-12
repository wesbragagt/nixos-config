/**
 * Domain types for the tmux-subagent extension.
 *
 * Value objects and entities shared across the domain layer.
 */

export type AgentScope = "user" | "project" | "both";

export interface AgentConfig {
	readonly name: string;
	readonly description: string;
	readonly tools: readonly string[] | undefined;
	readonly model: string | undefined;
	readonly systemPrompt: string;
	readonly source: "user" | "project";
	readonly filePath: string;
}

export interface AgentDiscoveryResult {
	readonly agents: readonly AgentConfig[];
	readonly projectAgentsDir: string | null;
}

export type DispatchMode = "single" | "parallel" | "chain";

export interface SubagentResult {
	readonly agent: string;
	readonly agentSource: "user" | "project" | "unknown";
	readonly task: string;
	readonly success: boolean;
	readonly output: string;
	readonly stderr: string;
	readonly exitCode: number;
	readonly tmuxWindowId: string | undefined;
	readonly durationMs: number;
}

export interface DispatchDetails {
	readonly mode: DispatchMode;
	readonly agentScope: AgentScope;
	readonly results: readonly SubagentResult[];
	readonly inTmux: boolean;
}

export interface TaskItem {
	readonly agent: string;
	readonly task: string;
	readonly cwd?: string;
}

export interface ParsedJsonEvent {
	readonly type: string;
	readonly [key: string]: unknown;
}

export interface AssistantMessage {
	readonly role: string;
	readonly content: ReadonlyArray<{ type: string; text?: string }>;
	readonly usage?: {
		readonly input?: number;
		readonly output?: number;
		readonly cacheRead?: number;
		readonly cacheWrite?: number;
		readonly cost?: { readonly total?: number };
		readonly totalTokens?: number;
	};
	readonly model?: string;
	readonly stopReason?: string;
	readonly errorMessage?: string;
}
