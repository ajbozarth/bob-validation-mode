#!/usr/bin/env node
/**
 * parse-chat.js
 * Usage: node parse-chat.js <export.json> [output.md]
 *
 * Extracts only the user/assistant conversation from a Bob chat export JSON.
 * Strips system messages, tool lists, metadata, environment details, etc.
 * Outputs clean Markdown. If no output path is given, prints to stdout.
 */

const fs = require("fs");

const [, , inputPath, outputPath] = process.argv;

if (!inputPath) {
  console.error("Usage: node parse-chat.js <export.json> [output.md]");
  process.exit(1);
}

const raw = JSON.parse(fs.readFileSync(inputPath, "utf8"));

const tasks = raw.tasks ?? [];
const lines = [];

for (const { task, messages } of tasks) {
  if (tasks.length > 1) {
    lines.push(`# ${task.title ?? "Untitled Task"}\n`);
  }

  for (const msg of messages ?? []) {
    const role = msg.role;
    if (role === "system") continue; // skip injected system prompt

    const rawContent =
      typeof msg.data?.content === "string" ? msg.data.content : "";

    let text = rawContent;

    if (role === "user") {
      // Extract only the <user_query> block; fall back to full content
      const match = rawContent.match(/<user_query>([\s\S]*?)<\/user_query>/);
      text = match ? match[1].trim() : rawContent.trim();
    }

    if (!text) continue;

    if (role === "user") {
      lines.push(`**User:** ${text}\n`);
    } else if (role === "assistant") {
      lines.push(`**Bob:** ${text}\n`);
    }

    lines.push("---\n");
  }
}

const output = lines.join("\n");

if (outputPath) {
  fs.writeFileSync(outputPath, output, "utf8");
  console.log(`Written to ${outputPath}`);
} else {
  process.stdout.write(output);
}
