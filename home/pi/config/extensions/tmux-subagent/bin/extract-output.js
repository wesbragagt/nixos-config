#!/usr/bin/env node
/**
 * Extract the last assistant text from a pi session JSONL file.
 *
 * Usage: extract-output.js <session-file-or-dir>
 *
 * Outputs the text content of the last assistant message to stdout.
 */

"use strict";

const { readFileSync, readdirSync, statSync } = require("node:fs");
const { join } = require("node:path");

function extractLastAssistantText(lines) {
	let lastText = "";

	for (const line of lines) {
		if (!line.trim()) continue;
		try {
			const entry = JSON.parse(line);
			if (entry.type === "message" && entry.message && entry.message.role === "assistant") {
				const content = entry.message.content;
				if (Array.isArray(content)) {
					for (const part of content) {
						if (part.type === "text" && part.text) {
							lastText = part.text;
						}
					}
				}
			}
		} catch {
			// skip malformed
		}
	}

	return lastText;
}

function findSessionFile(dir) {
	try {
		if (!statSync(dir).isDirectory()) return null;
	} catch {
		return null;
	}

	let entries;
	try {
		entries = readdirSync(dir).filter((e) => e.endsWith(".jsonl")).sort();
	} catch {
		return null;
	}

	if (entries.length === 0) return null;

	let newest = entries[0];
	let newestMtime = 0;

	for (const entry of entries) {
		const filePath = join(dir, entry);
		try {
			const mtime = statSync(filePath).mtimeMs;
			if (mtime > newestMtime) {
				newestMtime = mtime;
				newest = entry;
			}
		} catch {
			// skip
		}
	}

	return join(dir, newest);
}

const target = process.argv[2];

if (!target) {
	process.exit(1);
}

let sessionFile;

try {
	const stat = statSync(target);
	if (stat.isDirectory()) {
		sessionFile = findSessionFile(target) || "";
	} else {
		sessionFile = target;
	}
} catch {
	sessionFile = target;
}

if (!sessionFile) {
	process.exit(1);
}

try {
	const content = readFileSync(sessionFile, "utf-8");
	const lines = content.split("\n");
	const text = extractLastAssistantText(lines);
	process.stdout.write(text);
} catch {
	process.exit(1);
}
