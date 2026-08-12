/**
 * Agent discovery adapter.
 *
 * Discovers agent definitions from markdown files with YAML frontmatter
 * in ~/.pi/agent/agents/ and .pi/agents/.
 *
 * Port: AgentDiscoverer (implemented inline, no separate port file needed
 * since the application layer uses this directly through the app).
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { getAgentDir, parseFrontmatter } from "@earendil-works/pi-coding-agent";
import type { AgentConfig, AgentDiscoveryResult, AgentScope } from "../domain/types.js";

export class AgentDiscoveryAdapter {
	discover(cwd: string, scope: AgentScope): AgentDiscoveryResult {
		const userDir = path.join(getAgentDir(), "agents");
		const projectAgentsDir = this.findNearestProjectAgentsDir(cwd);

		const userAgents = scope === "project" ? [] : this.loadAgentsFromDir(userDir, "user");
		const projectAgents =
			scope === "user" || !projectAgentsDir ? [] : this.loadAgentsFromDir(projectAgentsDir, "project");

		const agentMap = new Map<string, AgentConfig>();

		if (scope === "both") {
			for (const agent of userAgents) agentMap.set(agent.name, agent);
			for (const agent of projectAgents) agentMap.set(agent.name, agent);
		} else if (scope === "user") {
			for (const agent of userAgents) agentMap.set(agent.name, agent);
		} else {
			for (const agent of projectAgents) agentMap.set(agent.name, agent);
		}

		return { agents: Array.from(agentMap.values()), projectAgentsDir };
	}

	private loadAgentsFromDir(dir: string, source: "user" | "project"): AgentConfig[] {
		const agents: AgentConfig[] = [];

		if (!fs.existsSync(dir)) return agents;

		let entries: fs.Dirent[];
		try {
			entries = fs.readdirSync(dir, { withFileTypes: true });
		} catch {
			return agents;
		}

		for (const entry of entries) {
			if (!entry.name.endsWith(".md")) continue;
			if (!entry.isFile() && !entry.isSymbolicLink()) continue;

			const filePath = path.join(dir, entry.name);
			let content: string;
			try {
				content = fs.readFileSync(filePath, "utf-8");
			} catch {
				continue;
			}

			const { frontmatter, body } = parseFrontmatter<Record<string, string>>(content);
			if (!frontmatter.name || !frontmatter.description) continue;

			const tools = frontmatter.tools
				?.split(",")
				.map((t: string) => t.trim())
				.filter(Boolean);

			agents.push({
				name: frontmatter.name,
				description: frontmatter.description,
				tools: tools && tools.length > 0 ? tools : undefined,
				model: frontmatter.model,
				systemPrompt: body,
				source,
				filePath,
			});
		}

		return agents;
	}

	private findNearestProjectAgentsDir(cwd: string): string | null {
		let currentDir = cwd;
		while (true) {
			const candidate = path.join(currentDir, ".pi", "agents");
			try {
				if (fs.statSync(candidate).isDirectory()) return candidate;
			} catch {
				// not a directory, continue
			}
			const parentDir = path.dirname(currentDir);
			if (parentDir === currentDir) return null;
			currentDir = parentDir;
		}
	}
}
