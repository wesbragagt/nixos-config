#!/usr/bin/env node
/**
 * JSON event stream formatter for tmux window display.
 *
 * Reads pi --mode json JSONL from stdin, outputs human-readable
 * tool calls and assistant text to stdout.
 */

"use strict";

let buffer = "";

process.stdin.on("data", (data) => {
	buffer += data.toString();
	const lines = buffer.split("\n");
	buffer = lines.pop() || "";

	for (const line of lines) {
		if (!line.trim()) continue;
		try {
			const event = JSON.parse(line);

			switch (event.type) {
				case "tool_execution_start":
					process.stdout.write(`\x1b[36m→ ${event.toolName}\x1b[0m\n`);
					break;

				case "tool_execution_end":
					if (event.isError) {
						process.stdout.write("\x1b[31m  ✗ error\x1b[0m\n");
					} else {
						process.stdout.write("\x1b[32m  ✓ done\x1b[0m\n");
					}
					break;

				case "message_end":
					if (event.message?.role === "assistant") {
						for (const part of event.message.content || []) {
							if (part.type === "text" && part.text?.trim()) {
								process.stdout.write("\n" + part.text + "\n");
							}
						}
					}
					break;

				case "agent_end":
					process.stdout.write("\n\x1b[33m━━━ complete ━━━\x1b[0m\n");
					break;
			}
		} catch {
			// skip malformed lines
		}
	}
});

process.stdin.on("end", () => {
	if (buffer.trim()) {
		try {
			JSON.parse(buffer);
		} catch {
			// ignore trailing partial
		}
	}
});
