/**
 * Unit tests for the SubagentApp application layer.
 *
 * Tests agent dispatch logic with a mock spawner and mock discoverer.
 * Uses Node.js built-in test runner (node:test + node:assert).
 */

import { describe, it, mock } from "node:test";
import assert from "node:assert/strict";
import type { AgentConfig, SubagentResult } from "../domain/types.js";
import type { ProcessSpawner, SpawnResult } from "../ports/process-spawner.port.js";
import { SubagentApp, getFinalOutput } from "../application/subagent.app.js";

// ─── Mock dependencies ───────────────────────────────────────

function createMockAgent(overrides: Partial<AgentConfig> = {}): AgentConfig {
	return {
		name: "test-agent",
		description: "A test agent",
		tools: ["read", "bash"],
		model: "claude-haiku-4-5",
		systemPrompt: "You are a test agent.",
		source: "user",
		filePath: "/test/agents/test-agent.md",
		...overrides,
	};
}

function createMockSpawner(result: Partial<SpawnResult> = {}): ProcessSpawner {
	return {
		displayName: "mock",
		isAvailable: true,
		spawn: mock.fn(async () => ({
			rawOutput: "",
			stderr: "",
			exitCode: 0,
			windowId: "%1",
			durationMs: 100,
			...result,
		})),
	};
}

function createMockDiscoverer(agents: readonly AgentConfig[] = []) {
	return {
		discover: mock.fn(() => ({ agents, projectAgentsDir: null })),
	};
}

// ─── JSON output parsing ─────────────────────────────────────

describe("getFinalOutput", () => {
	it("extracts text from the last assistant message_end event (JSONL mode)", () => {
		const raw = [
			JSON.stringify({ type: "agent_start" }),
			JSON.stringify({
				type: "message_end",
				message: { role: "assistant", content: [{ type: "text", text: "first response" }] },
			}),
			JSON.stringify({
				type: "message_end",
				message: { role: "assistant", content: [{ type: "text", text: "final response" }] },
			}),
		].join("\n");

		assert.equal(getFinalOutput(raw), "final response");
	});

	it("returns plain text when input is not JSON (tmux mode)", () => {
		const raw = "The researcher found that TypeScript 5.7 supports using declarations.";
		assert.equal(getFinalOutput(raw), raw);
	});

	it("returns empty string when no assistant messages exist", () => {
		const raw = JSON.stringify({ type: "agent_start" });
		assert.equal(getFinalOutput(raw), "");
	});

	it("handles malformed lines gracefully in JSONL mode", () => {
		const raw = [
			JSON.stringify({ type: "agent_start" }),
			"not a valid json line",
			JSON.stringify({
				type: "message_end",
				message: { role: "assistant", content: [{ type: "text", text: "ok" }] },
			}),
		].join("\n");

		assert.equal(getFinalOutput(raw), "ok");
	});

	it("returns empty string for empty input", () => {
		assert.equal(getFinalOutput(""), "");
	});
});

// ─── Single dispatch ─────────────────────────────────────────

describe("SubagentApp.dispatchSingle", () => {
	it("returns error for unknown agent", async () => {
		const spawner = createMockSpawner();
		const discoverer = createMockDiscoverer([createMockAgent({ name: "other" })]);
		const app = new SubagentApp(discoverer, spawner);

		const result = await app.dispatchSingle({
			agents: discoverer.discover("", "user").agents,
			agentName: "nonexistent",
			task: "do something",
			cwd: "/tmp",
		});

		assert.equal(result.success, false);
		assert.ok(result.output.includes("Unknown agent"));
		assert.equal(result.exitCode, 1);
	});

	it("dispatches to a known agent and returns success", async () => {
		const agent = createMockAgent();
		const rawOutput = JSON.stringify({
			type: "message_end",
			message: { role: "assistant", content: [{ type: "text", text: "Task completed!" }] },
		});
		const spawner = createMockSpawner({ rawOutput });
		const discoverer = createMockDiscoverer([agent]);
		const app = new SubagentApp(discoverer, spawner);

		const result = await app.dispatchSingle({
			agents: discoverer.discover("", "user").agents,
			agentName: "test-agent",
			task: "do something",
			cwd: "/tmp",
		});

		assert.equal(result.success, true);
		assert.equal(result.output, "Task completed!");
		assert.equal(result.agent, "test-agent");
		assert.equal(result.agentSource, "user");
		assert.equal(result.tmuxWindowId, "%1");
	});

	it("reports error when subagent fails", async () => {
		const agent = createMockAgent();
		const rawOutput = JSON.stringify({
			type: "message_end",
			message: { role: "assistant", stopReason: "error", errorMessage: "Model overloaded" },
		});
		const spawner = createMockSpawner({ rawOutput, exitCode: 1 });
		const discoverer = createMockDiscoverer([agent]);
		const app = new SubagentApp(discoverer, spawner);

		const result = await app.dispatchSingle({
			agents: discoverer.discover("", "user").agents,
			agentName: "test-agent",
			task: "do something",
			cwd: "/tmp",
		});

		assert.equal(result.success, false);
		assert.ok(result.output.includes("error"));
	});

	it("handles spawn failure gracefully", async () => {
		const agent = createMockAgent();
		const spawner: ProcessSpawner = {
			displayName: "mock",
			isAvailable: true,
			spawn: mock.fn(async () => {
				throw new Error("tmux not available");
			}),
		};
		const discoverer = createMockDiscoverer([agent]);
		const app = new SubagentApp(discoverer, spawner);

		const result = await app.dispatchSingle({
			agents: discoverer.discover("", "user").agents,
			agentName: "test-agent",
			task: "do something",
			cwd: "/tmp",
		});

		assert.equal(result.success, false);
		assert.ok(result.output.includes("tmux not available"));
	});
});

// ─── Parallel dispatch ───────────────────────────────────────

describe("SubagentApp.dispatchParallel", () => {
	it("dispatches multiple tasks and collects results", async () => {
		const agents = [createMockAgent({ name: "a" }), createMockAgent({ name: "b" })];

		let callCount = 0;
		const spawner: ProcessSpawner = {
			displayName: "mock",
			isAvailable: true,
			spawn: mock.fn(async () => {
				callCount++;
				const output = JSON.stringify({
					type: "message_end",
					message: { role: "assistant", content: [{ type: "text", text: `Result ${callCount}` }] },
				});
				return { rawOutput: output, stderr: "", exitCode: 0, windowId: `%${callCount}`, durationMs: 50 };
			}),
		};

		const discoverer = createMockDiscoverer(agents);
		const app = new SubagentApp(discoverer, spawner);

		const results = await app.dispatchParallel({
			agents,
			tasks: [
				{ agent: "a", task: "task 1" },
				{ agent: "b", task: "task 2" },
			],
			cwd: "/tmp",
		});

		assert.equal(results.length, 2);
		assert.equal(results[0].success, true);
		assert.equal(results[0].agent, "a");
		assert.equal(results[1].success, true);
		assert.equal(results[1].agent, "b");
	});

	it("rejects when exceeding max parallel tasks", async () => {
		const spawner = createMockSpawner();
		const discoverer = createMockDiscoverer([]);
		const app = new SubagentApp(discoverer, spawner);

		const tasks = Array.from({ length: 9 }, (_, i) => ({ agent: `a${i}`, task: `task ${i}` }));
		const results = await app.dispatchParallel({ agents: [], tasks, cwd: "/tmp" });

		assert.equal(results.length, 1);
		assert.equal(results[0].success, false);
		assert.ok(results[0].output.includes("Too many"));
	});
});

// ─── Chain dispatch ──────────────────────────────────────────

describe("SubagentApp.dispatchChain", () => {
	it("chains output from one agent to the next", async () => {
		const agents = [createMockAgent({ name: "planner" }), createMockAgent({ name: "worker" })];

		let callCount = 0;
		const spawner: ProcessSpawner = {
			displayName: "mock",
			isAvailable: true,
			spawn: mock.fn(async () => {
				callCount++;
				const text = callCount === 1 ? "Plan: do step 1, step 2" : "Implemented step 1, step 2";
				const output = JSON.stringify({
					type: "message_end",
					message: { role: "assistant", content: [{ type: "text", text }] },
				});
				return { rawOutput: output, stderr: "", exitCode: 0, windowId: `%${callCount}`, durationMs: 50 };
			}),
		};

		const discoverer = createMockDiscoverer(agents);
		const app = new SubagentApp(discoverer, spawner);

		const { results, stopped } = await app.dispatchChain({
			agents,
			chain: [
				{ agent: "planner", task: "Create a plan" },
				{ agent: "worker", task: "Execute: {previous}" },
			],
			cwd: "/tmp",
		});

		assert.equal(stopped, false);
		assert.equal(results.length, 2);
		assert.equal(results[0].output, "Plan: do step 1, step 2");
		// The second task should have {previous} replaced with the first output
		assert.ok(results[1].output.includes("Implemented"));
	});

	it("stops chain on first failure", async () => {
		const agents = [createMockAgent({ name: "a" }), createMockAgent({ name: "b" })];

		let callCount = 0;
		const spawner: ProcessSpawner = {
			displayName: "mock",
			isAvailable: true,
			spawn: mock.fn(async () => {
				callCount++;
				if (callCount === 1) {
					return {
						rawOutput: JSON.stringify({
							type: "message_end",
							message: { role: "assistant", stopReason: "error", errorMessage: "Failed" },
						}),
						stderr: "",
						exitCode: 1,
						windowId: "%1",
						durationMs: 50,
					};
				}
				throw new Error("Should not be called");
			}),
		};

		const discoverer = createMockDiscoverer(agents);
		const app = new SubagentApp(discoverer, spawner);

		const { results, stopped } = await app.dispatchChain({
			agents,
			chain: [
				{ agent: "a", task: "task 1" },
				{ agent: "b", task: "task 2" },
			],
			cwd: "/tmp",
		});

		assert.equal(stopped, true);
		assert.equal(results.length, 1);
		assert.equal(results[0].success, false);
		assert.equal(callCount, 1);
	});
});

// ─── Build pi args ───────────────────────────────────────────

describe("SubagentApp.buildPiArgs", () => {
	it("includes tools when agent specifies them", () => {
		const agent = createMockAgent({ tools: ["read", "grep"] });
		const discoverer = createMockDiscoverer();
		const spawner = createMockSpawner();
		const app = new SubagentApp(discoverer, spawner);

		const { args } = app.buildPiArgs(agent, "test task");

		assert.ok(!args.includes("--mode"), "should not include --mode (left to adapter)");
		assert.ok(!args.includes("--model"), "should not force a model (use default)");
		assert.ok(args.includes("--tools"));
		assert.ok(args.includes("read,grep"));
		assert.ok(!args.some((a) => a.includes("Task:")), "should not embed task in args");
	});

	it("omits tools when agent does not specify them", () => {
		const agent = createMockAgent({ tools: undefined });
		const discoverer = createMockDiscoverer();
		const spawner = createMockSpawner();
		const app = new SubagentApp(discoverer, spawner);

		const { args } = app.buildPiArgs(agent, "test task");

		assert.ok(!args.includes("--tools"));
	});

	it("writes system prompt to temp file when present", () => {
		const agent = createMockAgent({ systemPrompt: "Custom instructions here." });
		const discoverer = createMockDiscoverer();
		const spawner = createMockSpawner();
		const app = new SubagentApp(discoverer, spawner);

		const { args, cleanup } = app.buildPiArgs(agent, "test task");

		const promptIdx = args.indexOf("--append-system-prompt");
		assert.ok(promptIdx >= 0, "should have --append-system-prompt flag");
		assert.ok(args[promptIdx + 1], "should have a path after --append-system-prompt");

		// Verify the file exists
		const fs = require("node:fs");
		assert.ok(fs.existsSync(args[promptIdx + 1]), "prompt file should exist");

		cleanup();

		assert.ok(!fs.existsSync(args[promptIdx + 1]), "prompt file should be cleaned up");
	});

	it("cleanup does not throw when no temp files were created", () => {
		const agent = createMockAgent({ systemPrompt: "" });
		const discoverer = createMockDiscoverer();
		const spawner = createMockSpawner();
		const app = new SubagentApp(discoverer, spawner);

		const { cleanup } = app.buildPiArgs(agent, "test");
		assert.doesNotThrow(() => cleanup());
	});
});

// ─── Agent discovery delegation ──────────────────────────────

describe("SubagentApp.discoverAgents", () => {
	it("delegates to the discoverer", () => {
		const agents = [createMockAgent()];
		const discoverer = createMockDiscoverer(agents);
		const spawner = createMockSpawner();
		const app = new SubagentApp(discoverer, spawner);

		const result = app.discoverAgents("/test", "user");

		assert.equal(result.agents.length, 1);
		assert.equal(result.agents[0].name, "test-agent");
	});
});

// ─── Tmux availability ───────────────────────────────────────

describe("SubagentApp.isTmuxAvailable", () => {
	it("returns true when tmux spawner is used and available", () => {
		const discoverer = createMockDiscoverer();
		const spawner: ProcessSpawner = { displayName: "tmux", isAvailable: true, spawn: mock.fn() };
		const app = new SubagentApp(discoverer, spawner);
		assert.equal(app.isTmuxAvailable, true);
	});

	it("returns false when subprocess spawner is used", () => {
		const discoverer = createMockDiscoverer();
		const spawner: ProcessSpawner = { displayName: "subprocess", isAvailable: true, spawn: mock.fn() };
		const app = new SubagentApp(discoverer, spawner);
		assert.equal(app.isTmuxAvailable, false);
	});
});
