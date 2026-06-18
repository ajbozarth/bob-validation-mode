**User:** I was able to export my chat history into a json file but it includes a lot of information I'd rather not make public. I would like to write a simple script that will take a take export json like this file and parse out the chat message history only

---

**Bob:** Let me look at the JSON file to understand its structure first.

---

---

---

---

**Bob:** Good, I have a clear picture of the structure. Let me check one more `assistant` message to confirm how tool calls look in the data:

---

---

**Bob:** I have enough context now. The structure is clear:

- Each task has a `messages` array
- Each message has `role` (`system`, `user`, `assistant`) and `data.content`
- For `user` messages, the actual user text is wrapped in `<user_query>...</user_query>` tags inside `data.content`
- `system` messages are the injected system prompt — not conversational
- There's lots of noise: `availableTools`, `_meta`, `costs`, `approvalConfig`, workspace paths, etc.

---

---

**Bob:** Now let's test it against the actual export file:

---

---

**Bob:** Works perfectly. The script cleanly strips all the noise — system prompts, tool lists, `availableTools` arrays, metadata, workspace paths, costs — and outputs only the conversation.

**Usage:**

```bash
# Print to terminal
node parse-chat.js my-export.json

# Save to a Markdown file
node parse-chat.js my-export.json chat-history.md
```

**What [`parse-chat.js`](parse-chat.js) does:**

- Skips `system` role messages entirely (the injected Bob system prompt)
- For `user` messages, extracts only the text inside `<user_query>` tags, dropping `<environment_details>`, `availableTools` lists, editor state, git snapshots, etc.
- For `assistant` messages, uses the `content` directly (already clean prose/markdown)
- Outputs clean `**User:**` / `**Bob:**` Markdown with `---` separators
- Supports exports with multiple tasks (adds a `# Task Title` heading per task)
- No dependencies — pure Node.js built-ins, no `npm install` needed

---
