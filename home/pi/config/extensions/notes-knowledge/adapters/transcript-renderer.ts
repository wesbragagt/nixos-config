/**
 * Transcript renderer — pure function for converting session entries
 * into structured markdown transcripts.
 *
 * No filesystem or framework dependencies.
 */

const TOOL_OUTPUT_MAX_CHARS = 200;

export interface TranscriptMessage {
	readonly role: string;
	readonly content?: unknown;
	readonly toolName?: string;
	readonly isError?: boolean;
}

export interface TranscriptEntry {
	readonly type: string;
	readonly message?: TranscriptMessage;
	readonly summary?: string;
	readonly customType?: string;
}

function extractTextParts(content: unknown): string[] {
	if (typeof content === "string") return content ? [content] : [];
	if (!Array.isArray(content)) return [];

	const parts: string[] = [];
	for (const part of content) {
		if (part && typeof part === "object" && part.type === "text" && typeof part.text === "string") {
			parts.push(part.text);
		} else if (part && typeof part === "object" && part.type === "image") {
			parts.push("[image attached]");
		}
	}
	return parts;
}

function truncateToolOutput(content: unknown, maxChars: number): string {
	const text = extractTextParts(content).join("\n");
	if (text.length <= maxChars) return text;
	return `${text.slice(0, maxChars)}...`;
}

export function renderTranscript(
	entries: readonly TranscriptEntry[],
	sessionId: string,
	date: string,
	projectName: string,
): string {
	const lines: string[] = [];
	lines.push(`# Session: ${date}`);
	lines.push("");
	lines.push(`**Project**: ${projectName}`);
	lines.push(`**Session ID**: ${sessionId}`);
	lines.push("");
	lines.push("---");

	for (const entry of entries) {
		if (entry.type !== "message" || !entry.message) continue;

		const { role } = entry.message;

		if (role === "user") {
			const texts = extractTextParts(entry.message.content);
			if (texts.length === 0) continue;
			lines.push("");
			lines.push("## User");
			lines.push("");
			for (const text of texts) lines.push(text);
		} else if (role === "assistant") {
			const texts = extractTextParts(entry.message.content);
			if (texts.length === 0) continue;
			lines.push("");
			lines.push("## Assistant");
			lines.push("");
			for (const text of texts) lines.push(text);
		} else if (role === "toolResult") {
			const toolName = entry.message.toolName ?? "unknown";
			const output = truncateToolOutput(entry.message.content, TOOL_OUTPUT_MAX_CHARS);
			const errorPrefix = entry.message.isError ? " (error)" : "";
			lines.push("");
			lines.push(`## Tool: ${toolName}${errorPrefix}`);
			lines.push("");
			lines.push(output);
		}
	}

	return lines.join("\n");
}
