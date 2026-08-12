/**
 * Notes Knowledge Extension — Composition Root
 *
 * Wires domain entities, port interfaces, and framework adapters together.
 * This is the ONLY file that imports from @earendil-works/pi-coding-agent.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@earendil-works/pi-ai";
import { Text } from "@earendil-works/pi-tui";

import { FsStoreAdapter } from "./adapters/fs-store.adapter.js";
import { KnowledgeApp } from "./application/knowledge.app.js";

const KnowledgeActionSchema = StringEnum(["search", "read", "write", "list", "compact"] as const, {
	description: "Action to perform",
});

const KnowledgeParams = Type.Object({
	action: Type.Optional(KnowledgeActionSchema),
	query: Type.Optional(Type.String({ description: "Search query (for search action)" })),
	path: Type.Optional(Type.String({ description: "Wiki file path relative to wiki/ (for read/write/compact)" })),
	content: Type.Optional(Type.String({ description: "File content (for write action)" })),
});

export default function notesKnowledgeExtension(pi: ExtensionAPI): void {
	const store = new FsStoreAdapter();
	const app = new KnowledgeApp(store);

	// ─── Tool Registration ────────────────────────────────────
	pi.registerTool({
		name: "knowledge",
		label: "Knowledge",
		description: [
			"Search, read, write, and manage a project-specific knowledge base stored in ~/notes.",
			"Sections: raw/ (auto-saved session transcripts, read-only) and wiki/ (synthesized knowledge you manage).",
			"Use 'search' to find past knowledge, 'list' to see what exists, 'read'/'write' for wiki files, 'compact' to discover files needing consolidation.",
		].join(" "),
		promptSnippet: "Search, read, and manage project knowledge base in ~/notes (raw transcripts + synthesized wiki)",
		parameters: KnowledgeParams,

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const project = store.resolveProject(ctx.cwd);

			switch (params.action) {
				case "search": {
					if (!params.query) throw new Error("'query' is required for search action");
					const results = await store.search(project, params.query);
					if (results.length === 0) {
						return { content: [{ type: "text", text: "No results found." }] };
					}
					const formatted = results
						.map((r) => `[${r.file}:${r.lineNumber}] ${r.excerpt}`)
						.join("\n\n");
					return {
						content: [{ type: "text", text: `${results.length} result(s):\n\n${formatted}` }],
						details: { results },
					};
				}

				case "read": {
					if (!params.path) throw new Error("'path' is required for read action");
					const content = await store.readWiki(project, params.path);
					return { content: [{ type: "text", text: content }] };
				}

				case "write": {
					if (!params.path || params.content === undefined) {
						throw new Error("'path' and 'content' are required for write action");
					}
					await store.writeWiki(project, params.path, params.content);
					return {
						content: [{ type: "text", text: `Written to wiki/${params.path}` }],
						details: { path: params.path },
					};
				}

				case "list": {
					const listing = await app.listKnowledge(ctx.cwd);
					const lines: string[] = [];
					if (listing.raw.length > 0) {
						lines.push(`### Raw transcripts (${listing.raw.length})`);
						for (const r of listing.raw) {
							const marker = listing.unsynthesized.includes(r.sessionId) ? " ⬚" : "";
							lines.push(`  ${r.fileName}${marker}`);
						}
					}
					if (listing.wiki.length > 0) {
						lines.push(`\n### Wiki files (${listing.wiki.length})`);
						for (const w of listing.wiki) lines.push(`  ${w}`);
					}
					if (listing.unsynthesized.length > 0) {
						lines.push(`\n${listing.unsynthesized.length} unsynthesized session(s) pending wiki update.`);
					}
					if (lines.length === 0) lines.push("No knowledge files yet.");
					return {
						content: [{ type: "text", text: lines.join("\n") }],
						details: { raw: listing.raw, wiki: listing.wiki, unsynthesized: listing.unsynthesized },
					};
				}

				case "compact": {
					const wikiFiles = await store.listWiki(project);
					if (wikiFiles.length === 0) {
						return { content: [{ type: "text", text: "No wiki files to compact." }] };
					}
					if (params.path) {
						const content = await store.readWiki(project, params.path);
						return { content: [{ type: "text", text: content }] };
					}
					const names = wikiFiles.map((w) => w.name).join(", ");
					return {
						content: [{ type: "text", text: `Wiki files: ${names}\n\nUse 'compact' with a 'path' to read a specific file for consolidation, then 'write' the consolidated version.` }],
						details: { files: wikiFiles.map((w) => w.name) },
					};
				}

				default:
					throw new Error(`Unknown action: ${params.action}. Use search, read, write, list, or compact.`);
			}
		},

		renderCall(args, theme, _context) {
			const action = args.action ?? "...";
			const detail = args.query ? args.query : args.path ? args.path : "";
			const preview = detail.length > 50 ? `${detail.slice(0, 50)}...` : detail;
			let text = "🌳 " + theme.fg("toolTitle", theme.bold("knowledge ")) + theme.fg("accent", action);
			if (preview) text += theme.fg("dim", ` ${preview}`);
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded }, theme, _context) {
			const details = result.details as Record<string, unknown> | undefined;
			if (!details || !expanded) {
				const text = result.content[0];
				return new Text(text?.type === "text" ? text.text : "(no output)", 0, 0);
			}

			const lines: string[] = [];
			if (Array.isArray(details.results)) {
				for (const r of details.results as Array<{ file: string; lineNumber: number; excerpt: string }>) {
					lines.push(theme.fg("dim", `[${r.file}:${r.lineNumber}]`) + ` ${r.excerpt}`);
				}
			}
			if (Array.isArray(details.files)) {
				for (const f of details.files as string[]) {
					lines.push(theme.fg("accent", f));
				}
			}
			return new Text(lines.join("\n") || "(no details)", 0, 0);
		},
	});

	// ─── Event Handlers ───────────────────────────────────────

	pi.on("session_start", async (_event, ctx) => {
		const project = store.resolveProject(ctx.cwd);
		for (const dir of [project.knowledgeDir, project.rawDir, project.wikiDir]) {
			await fs.promises.mkdir(dir, { recursive: true });
		}

		const unsynthesized = await app.checkSynthesis(ctx.cwd);
		if (unsynthesized && unsynthesized.length > 0) {
			pi.sendMessage({
				customType: "notes-knowledge",
				content: `${unsynthesized.length} unsynthesized session(s) exist. Consider updating the wiki with relevant knowledge.`,
				display: false,
			});
		}
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		try {
			const entries = ctx.sessionManager.getBranch();
			const sessionId = ctx.sessionManager.getSessionId();
			const date = new Date().toISOString().split("T")[0];
			await app.saveTranscript(entries, sessionId, date, ctx.cwd);
		} catch {
			// Best-effort — don't block shutdown on knowledge save failures
		}
	});

	pi.on("before_agent_start", async (_event, ctx) => {
		const wikiContent = await app.injectWiki(ctx.cwd);
		if (!wikiContent) return;
		return {
			message: {
				customType: "notes-knowledge",
				content: wikiContent,
				display: false,
			},
		};
	});
}
