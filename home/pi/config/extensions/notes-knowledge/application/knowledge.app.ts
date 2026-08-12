/**
 * Knowledge application layer.
 *
 * Orchestrates transcript saving, wiki injection, and synthesis tracking.
 * Depends on the KnowledgeStorePort and the transcript renderer.
 */

import type { KnowledgeStorePort } from "../ports/knowledge-store.port.js";
import type { TranscriptEntry } from "../adapters/transcript-renderer.js";
import { renderTranscript } from "../adapters/transcript-renderer.js";

export class KnowledgeApp {
	constructor(private readonly store: KnowledgeStorePort) {}

	async saveTranscript(
		entries: readonly TranscriptEntry[],
		sessionId: string,
		date: string,
		cwd: string,
	): Promise<void> {
		const project = this.store.resolveProject(cwd);
		const markdown = renderTranscript(entries, sessionId, date, project.name);
		await this.store.writeRaw(project, {
			sessionId,
			date,
			filePath: `${project.rawDir}/${date}-${sessionId}.md`,
			fileName: `${date}-${sessionId}.md`,
		}, markdown);
	}

	async injectWiki(cwd: string): Promise<string | null> {
		const project = this.store.resolveProject(cwd);
		if (!await this.store.wikiIndexExists(project)) return null;
		return this.store.readWikiIndex(project);
	}

	async checkSynthesis(cwd: string): Promise<string[] | null> {
		const project = this.store.resolveProject(cwd);
		const raw = await this.store.listRaw(project);
		const manifest = await this.store.readManifest(project);
		const synthesizedSet = new Set(manifest.synthesized);
		const unsynthesized = raw
			.map((r) => r.sessionId)
			.filter((id) => !synthesizedSet.has(id));
		return unsynthesized.length > 0 ? unsynthesized : null;
	}

	async markSynthesized(cwd: string, sessionIds: string[]): Promise<void> {
		const project = this.store.resolveProject(cwd);
		const manifest = await this.store.readManifest(project);
		const merged = [...new Set([...manifest.synthesized, ...sessionIds])];
		await this.store.updateManifest(project, merged);
	}

	async listKnowledge(cwd: string): Promise<{
		raw: readonly { sessionId: string; date: string; fileName: string }[];
		wiki: readonly string[];
		unsynthesized: string[];
	}> {
		const project = this.store.resolveProject(cwd);
		const raw = await this.store.listRaw(project);
		const wiki = await this.store.listWiki(project);
		const unsynthesized = await this.checkSynthesis(cwd);
		return {
			raw: raw.map((r) => ({ sessionId: r.sessionId, date: r.date, fileName: r.fileName })),
			wiki: wiki.map((w) => w.name),
			unsynthesized: unsynthesized ?? [],
		};
	}
}
