/**
 * Unit tests for the notes-knowledge extension.
 *
 * Tests transcript renderer, filesystem adapter, and application layer.
 * Uses Node.js built-in test runner (node:test + node:assert).
 */

import { describe, it, mock, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { renderTranscript, type TranscriptEntry } from "../adapters/transcript-renderer.js";
import { FsStoreAdapter } from "../adapters/fs-store.adapter.js";
import { KnowledgeApp } from "../application/knowledge.app.js";
import type { KnowledgeStorePort, ProjectKey, SynthesisManifest } from "../domain/types.js";
import type { RawEntry, WikiFile, SearchResult } from "../domain/types.js";

// ─── Test helpers ────────────────────────────────────────────

let tmpDir: string;

function makeTmpDir(): string {
	return fs.mkdtempSync(path.join(os.tmpdir(), "nk-test-"));
}

beforeEach(() => { tmpDir = makeTmpDir(); });
afterEach(() => { fs.rmSync(tmpDir, { recursive: true, force: true }); });

function makeProjectKey(overrides: Partial<ProjectKey> = {}): ProjectKey {
	return {
		name: "test-project",
		notesDir: tmpDir,
		knowledgeDir: path.join(tmpDir, "pi", "knowledge", "test-project"),
		rawDir: path.join(tmpDir, "pi", "knowledge", "test-project", "raw"),
		wikiDir: path.join(tmpDir, "pi", "knowledge", "test-project", "wiki"),
		...overrides,
	};
}

// ─── Transcript Renderer ────────────────────────────────────

describe("renderTranscript", () => {
	it("returns header-only output for empty entries", () => {
		const result = renderTranscript([], "sess1", "2026-01-01", "proj");
		assert.ok(result.includes("# Session: 2026-01-01"));
		assert.ok(result.includes("**Project**: proj"));
		assert.ok(result.includes("**Session ID**: sess1"));
		assert.ok(!result.includes("## User"));
		assert.ok(!result.includes("## Assistant"));
	});

	it("renders user messages", () => {
		const entries: TranscriptEntry[] = [
			{ type: "message", message: { role: "user", content: "Hello world" } },
		];
		const result = renderTranscript(entries, "s1", "2026-01-01", "p");
		assert.ok(result.includes("## User"));
		assert.ok(result.includes("Hello world"));
	});

	it("renders assistant messages with text content parts", () => {
		const entries: TranscriptEntry[] = [
			{ type: "message", message: { role: "assistant", content: [{ type: "text", text: "Hi there" }] } },
		];
		const result = renderTranscript(entries, "s1", "2026-01-01", "p");
		assert.ok(result.includes("## Assistant"));
		assert.ok(result.includes("Hi there"));
	});

	it("renders assistant images as [image attached]", () => {
		const entries: TranscriptEntry[] = [
			{ type: "message", message: { role: "assistant", content: [{ type: "image", source: { type: "base64", mediaType: "image/png", data: "abc" } }] } },
		];
		const result = renderTranscript(entries, "s1", "2026-01-01", "p");
		assert.ok(result.includes("[image attached]"));
	});

	it("renders tool results truncated to 200 chars", () => {
		const longOutput = "x".repeat(500);
		const entries: TranscriptEntry[] = [
			{ type: "message", message: { role: "toolResult", toolName: "bash", content: longOutput } },
		];
		const result = renderTranscript(entries, "s1", "2026-01-01", "p");
		assert.ok(result.includes("## Tool: bash"));
		assert.ok(result.endsWith("..."));
		assert.ok(result.length < longOutput.length + 100);
	});

	it("renders tool results with error suffix", () => {
		const entries: TranscriptEntry[] = [
			{ type: "message", message: { role: "toolResult", toolName: "bash", content: "failed", isError: true } },
		];
		const result = renderTranscript(entries, "s1", "2026-01-01", "p");
		assert.ok(result.includes("## Tool: bash (error)"));
	});

	it("skips non-message entries (compaction, custom)", () => {
		const entries: TranscriptEntry[] = [
			{ type: "compaction", summary: "old stuff" },
			{ type: "custom", customType: "ext", message: undefined },
			{ type: "message", message: { role: "user", content: "keep me" } },
		];
		const result = renderTranscript(entries, "s1", "2026-01-01", "p");
		assert.ok(!result.includes("old stuff"));
		assert.ok(result.includes("keep me"));
	});

	it("skips user messages with empty content", () => {
		const entries: TranscriptEntry[] = [
			{ type: "message", message: { role: "user", content: "" } },
		];
		const result = renderTranscript(entries, "s1", "2026-01-01", "p");
		assert.ok(!result.includes("## User"));
	});

	it("skips messages without a message field", () => {
		const entries: TranscriptEntry[] = [
			{ type: "message" } as TranscriptEntry,
		];
		const result = renderTranscript(entries, "s1", "2026-01-01", "p");
		assert.ok(!result.includes("##"));
	});
});

// ─── FsStoreAdapter ─────────────────────────────────────────

describe("FsStoreAdapter", () => {
	describe("resolveProject", () => {
		it("falls back to directory basename when not a git repo", () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = adapter.resolveProject("/some/path/my-project");
			assert.equal(project.name, "my-project");
			assert.ok(project.rawDir.includes("my-project"));
		});

		it("caches project resolution", () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const p1 = adapter.resolveProject("/a/b/c");
			const p2 = adapter.resolveProject("/a/b/c");
			assert.equal(p1, p2);
		});
	});

	describe("readWiki / writeWiki", () => {
		it("writes and reads wiki files", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await fs.promises.mkdir(project.wikiDir, { recursive: true });
			await adapter.writeWiki(project, "decisions.md", "# Decisions\n- Use postgres");
			const content = await adapter.readWiki(project, "decisions.md");
			assert.equal(content, "# Decisions\n- Use postgres");
		});

		it("rejects path traversal attempts", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await fs.promises.mkdir(project.wikiDir, { recursive: true });
			await assert.rejects(
				() => adapter.readWiki(project, "../etc/passwd"),
				{ message: /path traversal/i },
			);
		});

		it("creates parent directories on write", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await adapter.writeWiki(project, "sub/nested.md", "content");
			const content = await adapter.readWiki(project, "sub/nested.md");
			assert.equal(content, "content");
		});
	});

	describe("listRaw", () => {
		it("parses raw filenames and skips non-md files", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await fs.promises.mkdir(project.rawDir, { recursive: true });
			await fs.promises.writeFile(path.join(project.rawDir, "2026-01-15-abc123.md"), "");
			await fs.promises.writeFile(path.join(project.rawDir, "2026-01-16-def456.md"), "");
			await fs.promises.writeFile(path.join(project.rawDir, "not-a-session.txt"), "");

			const raw = await adapter.listRaw(project);
			assert.equal(raw.length, 2);
			assert.equal(raw[0].sessionId, "abc123");
			assert.equal(raw[0].date, "2026-01-15");
			assert.equal(raw[1].sessionId, "def456");
		});

		it("returns empty array when raw dir does not exist", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			const raw = await adapter.listRaw(project);
			assert.equal(raw.length, 0);
		});
	});

	describe("listWiki", () => {
		it("lists md files excluding .manifest", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await fs.promises.mkdir(project.wikiDir, { recursive: true });
			await fs.promises.writeFile(path.join(project.wikiDir, "index.md"), "");
			await fs.promises.writeFile(path.join(project.wikiDir, "decisions.md"), "");
			await fs.promises.writeFile(path.join(project.wikiDir, ".manifest"), "{}");

			const wiki = await adapter.listWiki(project);
			assert.equal(wiki.length, 2);
			assert.equal(wiki[0].name, "decisions.md");
			assert.equal(wiki[1].name, "index.md");
		});
	});

	describe("readManifest / updateManifest", () => {
		it("returns empty manifest when missing", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			const manifest = await adapter.readManifest(project);
			assert.deepEqual(manifest.synthesized, []);
		});

		it("reads and updates manifest correctly", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await adapter.updateManifest(project, ["s1", "s2"]);
			const manifest = await adapter.readManifest(project);
			assert.deepEqual(manifest.synthesized, ["s1", "s2"]);

			await adapter.updateManifest(project, ["s1", "s2", "s3"]);
			const updated = await adapter.readManifest(project);
			assert.deepEqual(updated.synthesized, ["s1", "s2", "s3"]);
		});
	});

	describe("search", () => {
		it("returns matching excerpts across raw and wiki", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await fs.promises.mkdir(project.rawDir, { recursive: true });
			await fs.promises.mkdir(project.wikiDir, { recursive: true });
			await fs.promises.writeFile(path.join(project.rawDir, "2026-01-01-abc.md"), "decided to use postgres for auth\n");
			await fs.promises.writeFile(path.join(project.wikiDir, "index.md"), "# Auth\nWe use postgres.\n");

			const results = await adapter.search(project, "postgres");
			assert.ok(results.length >= 2);
			assert.ok(results.some((r) => r.file.includes("abc.md")));
			assert.ok(results.some((r) => r.file.includes("index.md")));
		});

		it("returns empty array when no matches", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await fs.promises.mkdir(project.rawDir, { recursive: true });
			await fs.promises.writeFile(path.join(project.rawDir, "2026-01-01-abc.md"), "hello world\n");

			const results = await adapter.search(project, "zzz-nonexistent");
			assert.equal(results.length, 0);
		});

		it("returns empty array when directories do not exist", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			const results = await adapter.search(project, "anything");
			assert.equal(results.length, 0);
		});
	});

	describe("wikiIndexExists / readWikiIndex", () => {
		it("returns false when index.md does not exist", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			assert.equal(await adapter.wikiIndexExists(project), false);
		});

		it("returns true and reads content when index.md exists", async () => {
			const adapter = new FsStoreAdapter(tmpDir);
			const project = makeProjectKey();
			await fs.promises.mkdir(project.wikiDir, { recursive: true });
			await fs.promises.writeFile(path.join(project.wikiDir, "index.md"), "# Wiki\n");
			assert.equal(await adapter.wikiIndexExists(project), true);
			assert.equal(await adapter.readWikiIndex(project), "# Wiki\n");
		});
	});
});

// ─── KnowledgeApp ───────────────────────────────────────────

describe("KnowledgeApp", () => {
	function createMockStore(overrides: Partial<KnowledgeStorePort> = {}): KnowledgeStorePort {
		return {
			resolveProject: mock.fn((_cwd: string) => makeProjectKey()),
			writeRaw: mock.fn(async () => {}),
			listRaw: mock.fn(async () => []),
			readWiki: mock.fn(async () => ""),
			writeWiki: mock.fn(async () => {}),
			listWiki: mock.fn(async () => []),
			readManifest: mock.fn(async () => ({ synthesized: [] })),
			updateManifest: mock.fn(async () => {}),
			search: mock.fn(async () => []),
			wikiIndexExists: mock.fn(async () => false),
			readWikiIndex: mock.fn(async () => ""),
			...overrides,
		};
	}

	it("saveTranscript delegates to store and renderer", async () => {
		let writtenContent = "";
		const store = createMockStore({
			writeRaw: mock.fn(async (_project, _entry, content) => { writtenContent = content; }),
		});
		const app = new KnowledgeApp(store);

		const entries: TranscriptEntry[] = [
			{ type: "message", message: { role: "user", content: "fix the bug" } },
			{ type: "message", message: { role: "assistant", content: [{ type: "text", text: "Fixed it" }] } },
		];
		await app.saveTranscript(entries, "s1", "2026-04-23", "/tmp");

		assert.ok(writtenContent.includes("# Session: 2026-04-23"));
		assert.ok(writtenContent.includes("fix the bug"));
		assert.ok(writtenContent.includes("Fixed it"));
	});

	it("injectWiki returns null when no index.md", async () => {
		const store = createMockStore({ wikiIndexExists: mock.fn(async () => false) });
		const app = new KnowledgeApp(store);
		const result = await app.injectWiki("/tmp");
		assert.equal(result, null);
	});

	it("injectWiki returns content when index.md exists", async () => {
		const store = createMockStore({
			wikiIndexExists: mock.fn(async () => true),
			readWikiIndex: mock.fn(async () => "# Wiki\nAuth uses JWT."),
		});
		const app = new KnowledgeApp(store);
		const result = await app.injectWiki("/tmp");
		assert.equal(result, "# Wiki\nAuth uses JWT.");
	});

	it("checkSynthesis detects unsynthesized sessions", async () => {
		const store = createMockStore({
			listRaw: mock.fn(async () => [
				{ sessionId: "s1", date: "2026-01-01", filePath: "/a", fileName: "f1" },
				{ sessionId: "s2", date: "2026-01-02", filePath: "/b", fileName: "f2" },
				{ sessionId: "s3", date: "2026-01-03", filePath: "/c", fileName: "f3" },
			] as readonly RawEntry[]),
			readManifest: mock.fn(async () => ({ synthesized: ["s1"] } as SynthesisManifest)),
		});
		const app = new KnowledgeApp(store);
		const unsynthesized = await app.checkSynthesis("/tmp");
		assert.deepEqual(unsynthesized, ["s2", "s3"]);
	});

	it("checkSynthesis returns null when all synthesized", async () => {
		const store = createMockStore({
			listRaw: mock.fn(async () => [
				{ sessionId: "s1", date: "2026-01-01", filePath: "/a", fileName: "f1" },
			] as readonly RawEntry[]),
			readManifest: mock.fn(async () => ({ synthesized: ["s1"] } as SynthesisManifest)),
		});
		const app = new KnowledgeApp(store);
		const result = await app.checkSynthesis("/tmp");
		assert.equal(result, null);
	});

	it("markSynthesized merges new IDs with existing manifest", async () => {
		const synthesized: string[][] = [];
		const store = createMockStore({
			readManifest: mock.fn(async () => ({ synthesized: ["s1"] } as SynthesisManifest)),
			updateManifest: mock.fn(async (_project, ids) => { synthesized.push(ids); }),
		});
		const app = new KnowledgeApp(store);
		await app.markSynthesized("/tmp", ["s2", "s3"]);
		assert.equal(synthesized.length, 1);
		assert.deepEqual(synthesized[0], ["s1", "s2", "s3"]);
	});

	it("markSynthesized deduplicates IDs", async () => {
		const synthesized: string[][] = [];
		const store = createMockStore({
			readManifest: mock.fn(async () => ({ synthesized: ["s1", "s2"] } as SynthesisManifest)),
			updateManifest: mock.fn(async (_project, ids) => { synthesized.push(ids); }),
		});
		const app = new KnowledgeApp(store);
		await app.markSynthesized("/tmp", ["s2", "s3"]);
		assert.deepEqual(synthesized[0], ["s1", "s2", "s3"]);
	});

	it("listKnowledge returns raw, wiki, and unsynthesized", async () => {
		const store = createMockStore({
			listRaw: mock.fn(async () => [
				{ sessionId: "s1", date: "2026-01-01", filePath: "/a", fileName: "f1" },
			] as readonly RawEntry[]),
			listWiki: mock.fn(async () => [
				{ name: "index.md", filePath: "/w/index.md" },
			] as readonly WikiFile[]),
			readManifest: mock.fn(async () => ({ synthesized: [] } as SynthesisManifest)),
		});
		const app = new KnowledgeApp(store);
		const listing = await app.listKnowledge("/tmp");
		assert.equal(listing.raw.length, 1);
		assert.equal(listing.wiki.length, 1);
		assert.deepEqual(listing.unsynthesized, ["s1"]);
	});
});
