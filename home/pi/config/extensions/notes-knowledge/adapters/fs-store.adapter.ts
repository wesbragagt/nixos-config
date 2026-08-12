/**
 * Filesystem adapter for the knowledge store port.
 *
 * Reads and writes knowledge files against ~/notes (or PI_NOTES_DIR).
 * Handles project resolution, path traversal protection, and grep-based search.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { execSync } from "node:child_process";
import type { ProjectKey, RawEntry, WikiFile, SynthesisManifest, SearchResult } from "../domain/types.js";
import type { KnowledgeStorePort } from "../ports/knowledge-store.port.js";

const RAW_FILENAME_RE = /^(\d{4}-\d{2}-\d{2})-(.+)\.md$/;

function getNotesDir(): string {
	return process.env.PI_NOTES_DIR ?? path.join(os.homedir(), "notes");
}

function buildProjectKey(name: string, notesDir: string): ProjectKey {
	const knowledgeDir = path.join(notesDir, "pi", "knowledge", name);
	return {
		name,
		notesDir,
		knowledgeDir,
		rawDir: path.join(knowledgeDir, "raw"),
		wikiDir: path.join(knowledgeDir, "wiki"),
	};
}

function extractRepoName(url: string): string | null {
	const patterns: RegExp[] = [
		/[:/]([^/]+?)\.git(?:\/?)$/,
		/[:/]([^/]+?)\/?$/,
	];
	for (const re of patterns) {
		const m = url.match(re);
		if (m) return m[1];
	}
	return null;
}

export class FsStoreAdapter implements KnowledgeStorePort {
	private readonly notesDir: string;
	private readonly projectCache = new Map<string, ProjectKey>();

	constructor(notesDir?: string) {
		this.notesDir = notesDir ?? getNotesDir();
	}

	resolveProject(cwd: string): ProjectKey {
		const cached = this.projectCache.get(cwd);
		if (cached) return cached;

		let name: string;
		try {
			const remoteUrl = execSync(`git -C "${cwd}" remote get-url origin`, {
				encoding: "utf-8",
				timeout: 5000,
				stdio: ["pipe", "pipe", "pipe"],
			}).trim();
			const repoName = extractRepoName(remoteUrl);
			name = repoName ?? path.basename(cwd);
		} catch {
			name = path.basename(cwd);
		}

		const key = buildProjectKey(name, this.notesDir);
		this.projectCache.set(cwd, key);
		return key;
	}

	async writeRaw(project: ProjectKey, entry: RawEntry, content: string): Promise<void> {
		await fs.promises.mkdir(project.rawDir, { recursive: true });
		await fs.promises.writeFile(entry.filePath, content, "utf-8");
	}

	async listRaw(project: ProjectKey): Promise<readonly RawEntry[]> {
		try {
			const files = await fs.promises.readdir(project.rawDir);
			const entries: RawEntry[] = [];
			for (const file of files) {
				const m = file.match(RAW_FILENAME_RE);
				if (!m) continue;
				const [, date, sessionId] = m;
				entries.push({
					sessionId,
					date,
					filePath: path.join(project.rawDir, file),
					fileName: file,
				});
			}
			return entries;
		} catch {
			return [];
		}
	}

	async readWiki(project: ProjectKey, wikiPath: string): Promise<string> {
		const resolved = path.resolve(project.wikiDir, wikiPath);
		if (!resolved.startsWith(project.wikiDir + path.sep) && resolved !== project.wikiDir) {
			throw new Error(`Path traversal rejected: ${wikiPath}`);
		}
		return fs.promises.readFile(resolved, "utf-8");
	}

	async writeWiki(project: ProjectKey, wikiPath: string, content: string): Promise<void> {
		const resolved = path.resolve(project.wikiDir, wikiPath);
		if (!resolved.startsWith(project.wikiDir + path.sep) && resolved !== project.wikiDir) {
			throw new Error(`Path traversal rejected: ${wikiPath}`);
		}
		await fs.promises.mkdir(path.dirname(resolved), { recursive: true });
		await fs.promises.writeFile(resolved, content, "utf-8");
	}

	async listWiki(project: ProjectKey): Promise<readonly WikiFile[]> {
		try {
			const files = await fs.promises.readdir(project.wikiDir);
			return files
				.filter((f) => f.endsWith(".md") && f !== ".manifest")
				.sort()
				.map((name) => ({
					name,
					filePath: path.join(project.wikiDir, name),
				}));
		} catch {
			return [];
		}
	}

	async readManifest(project: ProjectKey): Promise<SynthesisManifest> {
		try {
			const content = await fs.promises.readFile(
				path.join(project.wikiDir, ".manifest"),
				"utf-8",
			);
			const data = JSON.parse(content) as { synthesized?: string[] };
			return { synthesized: Array.isArray(data.synthesized) ? data.synthesized : [] };
		} catch {
			return { synthesized: [] };
		}
	}

	async updateManifest(project: ProjectKey, synthesized: string[]): Promise<void> {
		await fs.promises.mkdir(project.wikiDir, { recursive: true });
		const content = JSON.stringify({ synthesized }, null, 2) + "\n";
		await fs.promises.writeFile(path.join(project.wikiDir, ".manifest"), content, "utf-8");
	}

	async search(project: ProjectKey, query: string): Promise<readonly SearchResult[]> {
		const dirs = [project.rawDir, project.wikiDir].filter((d) => {
			try {
				fs.accessSync(d);
				return true;
			} catch {
				return false;
			}
		});

		if (dirs.length === 0) return [];

		try {
			const results = execSync(
				`grep -rn --include="*.md" -i ${JSON.stringify(query)} ${dirs.map((d) => JSON.stringify(d)).join(" ")} | head -n 20`,
				{ encoding: "utf-8", timeout: 10000, maxBuffer: 1024 * 1024 },
			);

			return results
				.trim()
				.split("\n")
				.filter((line) => line.includes(":"))
				.map((line) => {
					const colonIdx = line.indexOf(":");
					const absPath = line.slice(0, colonIdx);
					const rest = line.slice(colonIdx + 1);
					const lineNumColon = rest.indexOf(":");
					const lineNumber = parseInt(rest.slice(0, lineNumColon), 10) || 1;
					const excerpt = rest.slice(lineNumColon + 1).trim();
					const relative = path.relative(project.knowledgeDir, absPath);
					return { file: relative, excerpt, lineNumber };
				});
		} catch (error: unknown) {
			const code = error instanceof Error && "status" in error ? (error as { status: number }).status : 1;
			if (code === 1) return [];
			throw error;
		}
	}

	async wikiIndexExists(project: ProjectKey): Promise<boolean> {
		try {
			await fs.promises.access(path.join(project.wikiDir, "index.md"));
			return true;
		} catch {
			return false;
		}
	}

	async readWikiIndex(project: ProjectKey): Promise<string> {
		return fs.promises.readFile(path.join(project.wikiDir, "index.md"), "utf-8");
	}
}
