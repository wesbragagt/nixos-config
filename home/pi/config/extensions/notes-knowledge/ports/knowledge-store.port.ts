/**
 * Port interface for the knowledge store.
 *
 * Abstracts over filesystem operations for reading, writing,
 * and searching knowledge files. The application layer depends
 * on this port; adapters provide implementations.
 */

import type { ProjectKey, RawEntry, WikiFile, SynthesisManifest, SearchResult } from "../domain/types.js";

export interface KnowledgeStorePort {
	resolveProject(cwd: string): ProjectKey;

	writeRaw(project: ProjectKey, entry: RawEntry, content: string): Promise<void>;
	listRaw(project: ProjectKey): Promise<readonly RawEntry[]>;

	readWiki(project: ProjectKey, path: string): Promise<string>;
	writeWiki(project: ProjectKey, path: string, content: string): Promise<void>;
	listWiki(project: ProjectKey): Promise<readonly WikiFile[]>;

	readManifest(project: ProjectKey): Promise<SynthesisManifest>;
	updateManifest(project: ProjectKey, synthesized: string[]): Promise<void>;

	search(project: ProjectKey, query: string): Promise<readonly SearchResult[]>;

	wikiIndexExists(project: ProjectKey): Promise<boolean>;
	readWikiIndex(project: ProjectKey): Promise<string>;
}
