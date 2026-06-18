# Task 5 Plan — Markdown Validator (5a) & Mermaid Diagram Validator (5b)

## Overview

**Goal:** Deliver two validation features owned by the same developer — Task 5a (a pure skill for Markdown structural validation) and Task 5b (a two-layer validator: a new MCP tool for deterministic Mermaid syntax checking + a skill for semantic reasoning on top). Both produce output consistent with the mode's standard findings format.

**Scope:**
- `.bob/skills/markdown-validator/SKILL.md` — reasoning-based Markdown rule checker (5a)
- `mcp-server/` — new MCP server with a `validate_mermaid` tool (5b); scaffolded as a proper Node.js project with `src/`, `package.json`, and a build step
- `.bob/skills/mermaid-validator/SKILL.md` — skill that calls the MCP tool then applies semantic reasoning (5b)
- `.bob/mcp.json` — register the new MCP server alongside the existing `mcp-pylint` entry

**Non-goals:**
- No auto-fix of Markdown — report only, do not rewrite
- No ASCII diagram validation (out of scope per IDEAS.md)
- No new Bob mode changes — the mode already has `mcp`, `skill`, and `subagent` groups

**Key constraints:**
- All findings must follow the mode's standard format: **severity** (error / warning / suggestion), **location**, **description**, **recommended fix** — followed by a confidence score (0–100) and one-line verdict
- The `mcp-server/` can be a proper Node.js project (with `package.json`, `src/`, and a `build/` output) — it does not need to mirror the pre-built artifact style of `mcp-pylint`; use whichever structure is cleaner for the implementation
- The skill pattern to follow is `.bob/skills/dellmify/SKILL.md`: YAML frontmatter (`name`, `description`), numbered step workflow, explicit output format definition, usage examples

---

## Sub-Tasks

---

### 5a — Markdown Validator Skill

**Status:** `[ ] pending`

**Intent:**
Provide Bob with a structured checklist and workflow for validating any Markdown document. This is a pure skill — no external tooling needed. Bob applies LLM reasoning to check structural and semantic correctness.

**Expected Outcomes:**
- `skills/markdown-validator/SKILL.md` exists
- The skill defines a numbered workflow Bob follows on invocation
- The skill embeds a comprehensive rule checklist Bob checks against
- Output is a structured findings list (severity / location / description / fix) plus confidence score and verdict
- The skill explicitly instructs Bob to skip fenced code blocks and inline code (validate prose/structure only)
- A usage example with sample input and expected output is included in the skill file

**Todo List:**
1. Read the dellmify reference skill (`.bob/skills/dellmify/SKILL.md`) to confirm SKILL.md schema and frontmatter
2. Determine the full Markdown rule checklist — see the checklist section below
3. Create `skills/markdown-validator/` directory and write `SKILL.md`
4. Define the workflow steps in the skill (identify doc → apply checklist → produce findings → score → verdict)
5. Define the output format block explicitly in the skill — match the mode's standard format
6. Add a usage example section with a sample Markdown snippet containing violations and the expected findings output
7. Test manually against `README.md` and `docs/IDEAS.md` in the repo; confirm output format is correct

**Markdown Rule Checklist (encode in the skill):**

| Rule | Severity |
|------|----------|
| Heading levels are not skipped (e.g. H1 → H3 without H2) | error |
| Document has exactly one H1 (or zero — but not more than one) | warning |
| No bare URLs — links should use `[text](url)` syntax | warning |
| Link targets are not obviously broken (empty href, malformed `[]()`) | error |
| Fenced code blocks have a language tag (` ```python ` not ` ``` `) | suggestion |
| Fenced code blocks are properly closed — no unclosed fences | error |
| Tables have consistent column counts across header, separator, and rows | error |
| Table separator row uses only `-`, `:`, and `|` characters | error |
| Image tags have non-empty `alt` text | warning |
| No trailing whitespace on lines (common copy/paste artifact) | suggestion |
| No multiple consecutive blank lines (more than two) | suggestion |
| Inline HTML tags are closed where opened | warning |
| Front matter (YAML `---` block) is valid and closed | error |

**Relevant Context:**
- Skill frontmatter schema: `name`, `description` fields (see `.bob/skills/dellmify/SKILL.md` lines 1–4)
- The mode's findings format is defined in `.bob/custom_modes.yaml` `customInstructions` (lines 56–61)
- Test fixtures: `README.md` and `docs/IDEAS.md`
- Skill location: `.bob/skills/markdown-validator/SKILL.md`

---

### 5b-i — `validate_mermaid` MCP Tool

**Status:** `[ ] pending`

**Intent:**
Run the actual Mermaid CLI parser against a provided diagram string and return a structured pass/fail result. This produces deterministic, parser-sourced error messages — not LLM guesses about syntax correctness.

**Expected Outcomes:**
- `mcp-server/build/index.js` is a working MCP server exposing the `validate_mermaid` tool
- The tool accepts a `diagram` string (the raw Mermaid code, without the fenced code block markers)
- The tool runs the `@mermaid-js/mermaid-cli` parser (`mmdc`) against the input
- Returns structured output: `{ valid: boolean, errors: [{ line, message }] }` as JSON text
- If `mmdc` is not installed, the tool returns a clear error message rather than crashing
- `.bob/mcp.json` is updated to register `mcp-server` alongside the existing `mcp-pylint` entry

**Todo List:**
1. Read the MCP server build guide (`build-mcp-server` skill) to confirm the `registerTool` API and transport setup
2. Read `mcp-pylint/build/index.js` in full — use it as the implementation template (same SDK, same pattern)
3. Scaffold `mcp-server/` as a proper Node.js project:
   - `mcp-server/package.json` — `type: "module"`, dependencies: `@modelcontextprotocol/sdk`, `@mermaid-js/parser`, `zod`; build script to compile `src/` → `build/`
   - `mcp-server/src/index.ts` (or `.js`) — server entrypoint
   - `mcp-server/build/` — compiled output (what `.bob/mcp.json` points to)
5. Implement `validate_mermaid` in the server:
   - Import `McpServer`, `StdioServerTransport`, `z`
   - Register `validate_mermaid` tool with `inputSchema: z.object({ diagram: z.string() })`
   - Call `@mermaid-js/parser`'s parse API on the diagram string (in-process, no CLI or temp files needed)
   - On parse success: return `{ valid: true }` as JSON text
   - On parse error: return `{ valid: false, errors: [{ message: err.message }] }` as JSON text
   - If the parser throws unexpectedly, return `isError: true` with the raw error message
6. Update `.bob/mcp.json` — add `"mcp-server": { "command": "node", "args": ["./mcp-server/build/index.js"] }`
7. Smoke test: invoke the tool with a valid Mermaid diagram and a broken one; confirm correct structured output in both cases

**Relevant Context:**
- MCP server template: `mcp-pylint/build/index.js`
- MCP registration: `.bob/mcp.json` — append, do not replace the existing `mcp-pylint` entry
- The MCP tool's `description` field is what Bob reads to understand when to call it — write it clearly: "Run the Mermaid parser on a diagram string and return syntax validation results. Use this for hard syntax errors — not semantic review."

---

### 5b-ii — Mermaid Validator Skill

**Status:** `[ ] pending`

**Intent:**
Give Bob a workflow for validating Mermaid diagrams that uses the MCP tool for hard syntax errors and Bob's own reasoning for semantic coherence. The skill bridges deterministic tooling and LLM reasoning into a single user-facing output.

**Expected Outcomes:**
- `skills/mermaid-validator/SKILL.md` exists
- The skill defines a two-phase workflow:
  1. **Phase 1 (syntax):** Extract the Mermaid code block from the artifact, call `validate_mermaid` via the MCP tool, report any errors with "Source: Mermaid parser" attribution
  2. **Phase 2 (semantic):** Check whether the diagram's structure matches its stated purpose (title, surrounding prose description, or user-provided intent) — this is LLM reasoning, not the tool
- Syntax errors (Phase 1) are always reported as `error` severity
- Semantic issues (Phase 2) are `warning` or `suggestion` depending on degree
- Findings from both phases are merged into a single structured output list
- A usage example showing a valid diagram, a syntax-broken diagram, and a semantically mismatched diagram is included

**Todo List:**
1. Confirm sub-task 5b-i is complete and `validate_mermaid` is registered and working
2. Write `.bob/skills/mermaid-validator/SKILL.md`:
   - Frontmatter: `name: mermaid-validator`, `description: ...`
   - Step 1: Locate all Mermaid code blocks in the provided artifact (fenced with ` ```mermaid `)
   - Step 2: For each block, call the `validate_mermaid` MCP tool with the raw diagram string
   - Step 3: Map any tool errors to severity=error findings, attribute as "Source: Mermaid parser"
   - Step 4: Apply semantic coherence checks (see checklist below)
   - Step 5: Merge findings, compute confidence score, produce verdict
3. Define semantic coherence checklist in the skill (see below)
4. Add usage example section with three scenario samples
5. Test against a Markdown file with an embedded Mermaid diagram (create a test fixture if none exists)

**Semantic Coherence Checklist (encode in the skill):**

| Check | Severity |
|-------|----------|
| Diagram type matches the described content (e.g., a `sequenceDiagram` should show sequential interactions, not a static hierarchy) | warning |
| Node and edge labels are meaningful — not placeholders like "Node1", "A", "B" | suggestion |
| Diagram direction (`LR`, `TD`, etc.) is appropriate for the content | suggestion |
| All nodes referenced in edges are defined (may overlap with parser — include anyway as a reasoning check) | error |
| Diagram title (if present) matches the surrounding prose description | warning |
| No orphan nodes — every node participates in at least one edge | warning |

**Relevant Context:**
- Sub-task 5b-i must be complete before this skill is authored (need the tool name to reference in the skill)
- Skill pattern: `.bob/skills/dellmify/SKILL.md` — all skills live under `.bob/skills/`
- Findings format: severity / location / description / recommended fix (from `.bob/custom_modes.yaml`)
- Task 5a's skill handles Markdown structure — Mermaid extraction logic in 5a (detecting ` ```mermaid ` fences) is shared context but each skill is independent

---

## Dependency Order

```
5a (Markdown Validator Skill)  — independent, start first

5b-i (validate_mermaid MCP tool)  — no dependencies, can start in parallel with 5a

5b-ii (Mermaid Validator Skill)  — depends on 5b-i being complete and tested
```

All three sub-tasks can be worked within a single developer's session. The recommended order is:
1. 5a — fastest win, pure skill, no tooling
2. 5b-i — MCP tool; most technically uncertain piece (library choice)
3. 5b-ii — skill that consumes the MCP tool from 5b-i

---

## Open Questions / Decisions Needed

1. **Semantic checklist coverage** — the plan encodes 6 semantic checks for Mermaid and 13 structural rules for Markdown. Validate completeness at implementation time and adjust as needed.
