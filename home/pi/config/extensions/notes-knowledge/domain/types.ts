/**
 * Domain types for the notes-knowledge extension.
 *
 * Value objects shared across the domain layer.
 * Zero dependencies on framework or filesystem.
 */

export interface ProjectKey {
	readonly name: string;
	readonly notesDir: string;
	readonly knowledgeDir: string;
	readonly rawDir: string;
	readonly wikiDir: string;
}

export interface RawEntry {
	readonly sessionId: string;
	readonly date: string;
	readonly filePath: string;
	readonly fileName: string;
}

export interface WikiFile {
	readonly name: string;
	readonly filePath: string;
}

export interface SynthesisManifest {
	readonly synthesized: readonly string[];
}

export interface SearchResult {
	readonly file: string;
	readonly excerpt: string;
	readonly lineNumber: number;
}
