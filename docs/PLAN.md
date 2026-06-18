# Bob Validation Mode — Hackathon Plan

## Overview

**Goal:** Build a working Bob custom mode — `bob-validation` — that adds a structured self-review layer to Bob's outputs. Users invoke the mode to validate any generated artifact before acting on it. Six developers work in parallel on independent skills and features, converging at the end for integration and submission.

**Scope:** Custom mode definition, a set of composable validation skills, one MCP server for deterministic external validation, and the submission deliverables required by `docs/SUBMISSION_REQUIREMENTS.md`.

**Skills vs MCP tools:**
- **Skills (SKILL.md)** are prompt instruction documents loaded into Bob's context. They are the right tool for reasoning-based validation: DeLLMify, Confidence Score, Requirements Cross-Check, Bob Council, and Markdown validation.
- **MCP tools** execute external binaries or APIs and return deterministic results. They are the right tool where LLM reasoning is not sufficient: Mermaid syntax (run the actual parser) and code linting (run ESLint/Pylint).
- The mode already has the `mcp` permission group enabled — both are usable together.

**Non-goals:**
- No sandboxed arbitrary code execution
- No replication of Bob's core coding/generation functionality
- No Mellea integration in this hackathon window (TBD future work)

**Delivery artifacts:**
- `.bob/custom_modes.yaml` — active mode definition
- `skills/` — one SKILL.md per reasoning-based validation feature
- `mcp-server/` — one MCP server exposing deterministic validator tools
- `README.md` — install and usage instructions
- Demo video, problem statement, and submission zip

---

## Sub-Tasks

---

### Task 1 — Bob Council (Multi-Agent Review)

**Status:** `[ ] pending`

**Intent:**
Bob Council is the flagship feature. An orchestrator Bob spawns multiple subagents, each embodying a named reviewer persona. Every persona reviews the submitted artifact independently, then the orchestrator synthesizes their findings into a single consolidated report. This avoids circular reasoning by keeping each persona's review isolated until synthesis.

**Personas (suggested starting set — can be adjusted):**
- 🔎 The Critic — finds flaws, gaps, and contradictions
- 🌟 The Optimist — identifies strengths and what is working well
- 🔐 The Security Auditor — flags sensitive data, insecure patterns, and prompt injection artifacts
- 📐 The Pedant — checks grammar, formatting, style, and structural correctness
- 🧭 The Requirements Reviewer — checks coverage against any stated requirements or acceptance criteria

**Expected Outcomes:**
- A `skills/bob-council/SKILL.md` that defines the Council skill
- The skill instructs Bob to spawn one subagent per persona using `spawn_subagent`
- Each subagent receives the artifact and its persona's specific review lens
- The orchestrator collects all reviews and produces a structured synthesis report
- The skill can be invoked standalone or triggered from within the mode

**Todo List:**
1. Read the Bob skill authoring guide (`create-skill` skill) to understand SKILL.md schema and frontmatter
2. Define the list of Council personas and their individual review instructions
3. Write `skills/bob-council/SKILL.md` with orchestration instructions
4. Define the synthesis report format (findings per persona + consensus verdict + overall confidence)
5. Test with at least one artifact type (Markdown document recommended as first target)
6. Document usage example in the skill file

**Relevant Context:**
- Bob's `spawn_subagent` tool is available in the `subagent` permission group (already in the mode's `groups`)
- The mode's `customInstructions` in `.bob/custom_modes.yaml` should reference when to invoke the Council
- See `docs/IDEAS.md` — "Bob Council" section for original framing

---

### Task 2 — DeLLMify Pass

**Status:** `[ ] pending`

**Intent:**
Many AI-generated outputs contain hedging phrases, filler words, and overly deferential language ("Certainly!", "It's worth noting that", "As an AI language model..."). The DeLLMify skill detects and removes these patterns, improving directness and human readability of any output.

**Expected Outcomes:**
- A `skills/dellmify/SKILL.md` that defines the DeLLMify skill
- The skill provides Bob with a curated list of LLM-like patterns to detect and flag
- Bob produces a cleaned version of the input with flagged substitutions shown
- Works on any text artifact (Markdown, prose, code comments, governing docs)
- Can be run standalone or as a post-processing step on another skill's output

**Todo List:**
1. Read the Bob skill authoring guide (`create-skill` skill) to understand SKILL.md schema
2. Research and compile a comprehensive list of LLM-like phrases, hedges, and filler patterns
3. Write `skills/dellmify/SKILL.md` with detection instructions and the pattern list
4. Define output format: original text, flagged occurrences, cleaned version, and a "LLM-language density" score
5. Test against sample outputs from Bob (pull from `bob-chat-history/` for realistic examples)
6. Document usage example in the skill file

**Relevant Context:**
- `bob-chat-history/ajbozarth/parse-chat.md` and `bob-chat-history/mattborgard/initial-mode.md` contain real Bob output that can serve as test material
- The `scripts/parse-chat.js` script can extract clean chat history from exports for use as test input
- See `docs/IDEAS.md` — "DeLLMify" section for original framing

---

### Task 3 — Confidence Score

**Status:** `[ ] pending`

**Intent:**
Attach a structured confidence rating to any generated output before the user acts on it. The score surfaces uncertainty — whether due to ambiguous input, limited grounding, speculative reasoning, or conflicting sources — so users know how much to trust the output.

**Expected Outcomes:**
- A `skills/confidence-score/SKILL.md` that defines the Confidence Score skill
- The skill instructs Bob to assess its own output across defined uncertainty dimensions
- Output includes a numeric score (0–100), a breakdown by dimension, and a plain-language explanation of what drove the score down
- Works on any artifact type
- Can be appended to any other skill's output as a final step

**Todo List:**
1. Read the Bob skill authoring guide (`create-skill` skill) to understand SKILL.md schema
2. Define the uncertainty dimensions to evaluate (e.g. grounding, source confidence, ambiguity, completeness, recency)
3. Write `skills/confidence-score/SKILL.md` with scoring instructions and dimension definitions
4. Define the output block format: numeric score + dimension breakdown + narrative explanation + recommendation (act / review / discard)
5. Consider how the score interacts with Bob Council output (Council should feed into score)
6. Test against outputs of varying certainty levels
7. Document usage example in the skill file

**Relevant Context:**
- The existing `customInstructions` in `.bob/custom_modes.yaml` already references a confidence score (0–100) — this skill formalizes that behavior
- Score output should be consistent with the findings format already defined in the mode: severity / location / description / fix
- See `docs/IDEAS.md` — "Confidence Score" section for original framing

---

### Task 4 — Requirements Cross-Check

**Status:** `[ ] pending`

**Intent:**
Given a source requirements document (user story, acceptance criteria, PR-FAQ, OpA, Epic, or any structured spec), validate that a generated artifact fully covers the stated requirements. Flag gaps, contradictions, and missing coverage. Governing document validation (checking an OpA or Epic against its template) is a sub-case of this same pattern.

**Expected Outcomes:**
- A `skills/requirements-check/SKILL.md` that defines the Requirements Cross-Check skill
- The skill instructs Bob to extract requirements from a provided source document and map each one to the artifact under review
- Output is a coverage matrix: each requirement marked as covered / partially covered / missing, with evidence from the artifact
- Contradictions between the artifact and requirements are flagged as errors
- Governing document sub-case: the "requirements" are the template fields (e.g. OpA sections) and the artifact is the filled-in document

**Todo List:**
1. Read the Bob skill authoring guide (`create-skill` skill) to understand SKILL.md schema
2. Define what "a requirement" means across different source doc types (acceptance criteria bullet, PR-FAQ answer, Epic field, template section)
3. Write `skills/requirements-check/SKILL.md` with extraction and mapping instructions
4. Define the coverage matrix output format (per-requirement: status + evidence + gap description)
5. Add the governing document sub-case with guidance on common IBM doc templates (OpA, PR-FAQ, Epic)
6. Test with a sample requirements doc and a generated artifact
7. Document usage examples for both the general case and the governing document sub-case

**Relevant Context:**
- This is likely the highest product-value feature — position it prominently in the README and demo
- The `docs/SUBMISSION_REQUIREMENTS.md` in this repo is itself a requirements doc that could be used as a test fixture
- Bob Council's "Requirements Reviewer" persona (Task 1) should call this skill, creating a natural integration point
- See `docs/IDEAS.md` — "Validate Against Requirements" and "Governing documents" sections

---

### Task 5a — Markdown Validator

**Status:** `[ ] pending`

**Intent:**
Validate the structural and semantic correctness of a Markdown artifact. Catch broken links, malformed tables, skipped heading levels, unclosed code blocks, and other issues that would degrade readability or rendering.

**Expected Outcomes:**
- A `skills/markdown-validator/SKILL.md` that defines the Markdown Validator skill
- The skill instructs Bob to check a Markdown document against a defined set of structural rules
- Output is a structured findings list: severity / location / description / recommended fix
- Works on any Markdown artifact: README files, plans, blog posts, documentation

**Todo List:**
1. Read the Bob skill authoring guide (`create-skill` skill) to understand SKILL.md schema
2. Define the full checklist of Markdown structural rules (heading hierarchy, link syntax, table alignment, code fence language tags, image alt text, etc.)
3. Write `skills/markdown-validator/SKILL.md` with the rule checklist and check instructions
4. Define findings output format consistent with the mode's standard format
5. Test against `README.md` and `docs/IDEAS.md` in this repo as fixtures
6. Document usage example in the skill file

**Relevant Context:**
- The mode's standard findings format is already defined in `.bob/custom_modes.yaml` `customInstructions` — match it
- `README.md` and `docs/IDEAS.md` are available as test fixtures in the repo
- See `docs/IDEAS.md` — "Markdown" section under "Artifact Types to Validate"

---

### Task 5b — Mermaid Diagram Validator

**Status:** `[ ] pending`

**Intent:**
Validate Mermaid diagram syntax embedded in Markdown or provided standalone. Unlike the other skill-based validators, Mermaid syntax validation is deterministic — the Mermaid CLI either parses a diagram or it doesn't. This task therefore has two layers: an MCP tool that runs the actual Mermaid parser for hard syntax errors, and a skill that handles semantic coherence (does the diagram represent what it claims to show?) which requires reasoning.

**Expected Outcomes:**
- An MCP tool (`mcp-server/`) that accepts a Mermaid code block and returns a structured pass/fail result from the Mermaid CLI parser
- A `skills/mermaid-validator/SKILL.md` that instructs Bob to: (1) call the MCP tool for syntax validation, (2) apply semantic coherence reasoning on top of the deterministic result
- Hard syntax errors come from the MCP tool — deterministic, not LLM-guessed
- Semantic check (does the diagram match its stated purpose / surrounding prose?) comes from Bob's reasoning
- Output follows the standard findings format, with syntax errors marked as sourced from the parser

**Todo List:**
1. Read the Bob skill authoring guide (`create-skill` skill) to understand SKILL.md schema
2. Read the MCP server build guide (`build-mcp-server` skill) to understand how to scaffold and register the server
3. Scaffold `mcp-server/` — a small Node.js MCP server with a single `validate_mermaid` tool
4. Implement `validate_mermaid`: extract the diagram string, run it through the `@mermaid-js/mermaid` parser (or Mermaid CLI), return structured pass/fail with error location
5. Register the MCP server in `.bob/mcp.json` so it is available within the workspace
6. Write `skills/mermaid-validator/SKILL.md` — instructs Bob to call `validate_mermaid` first, then apply semantic coherence reasoning
7. Test with Markdown files containing valid diagrams, syntax-broken diagrams, and semantically wrong diagrams
8. Document usage example in the skill file

**Relevant Context:**
- Task 5a (Markdown Validator) and 5b (Mermaid Validator) are owned by the same developer but tracked separately
- Mermaid blocks appear inside Markdown as fenced code blocks with the `mermaid` language tag — extraction logic is shared with Task 5a
- The `build-mcp-server` skill (available in Bob) documents the MCP server scaffolding pattern
- The mode already has `mcp` in its `groups` — no mode changes needed to use the new tool
- See `docs/IDEAS.md` — "Diagrams" section under "Artifact Types to Validate"

---

### Task 6 — Code Style Validator ⚠️ Stretch Goal

**Status:** `[ ] pending`

**Intent:**
Validate code artifacts by invoking real linters via an MCP tool — not LLM reasoning about style. A skill that "guesses" at code style issues is weak; actual linter output is deterministic and trustworthy. This task extends the MCP server from Task 5b with additional linter tools, then provides a thin skill that orchestrates the tool calls and formats results.

**Expected Outcomes:**
- Additional MCP tools added to `mcp-server/`: `lint_javascript` (ESLint) and `lint_python` (Pylint or Ruff)
- Each tool accepts a code string and optional config, runs the appropriate linter, and returns structured findings
- A `skills/code-style-validator/SKILL.md` that instructs Bob to call the appropriate linter tool based on detected language, then present results in the standard findings format
- Security anti-patterns are explicitly out of scope (covered by Bob Council's Security Auditor persona)
- Output follows the standard findings format, with findings marked as sourced from the linter

**Todo List:**
1. Confirm Task 5b's MCP server scaffold is in place (this task extends it — coordinate with Task 5b developer)
2. Read the MCP server build guide (`build-mcp-server` skill) to understand tool registration pattern
3. Add `lint_javascript` tool to `mcp-server/`: shell out to ESLint, accept code string + optional `.eslintrc` config, return structured findings
4. Add `lint_python` tool to `mcp-server/`: shell out to Pylint or Ruff, accept code string, return structured findings
5. Write `skills/code-style-validator/SKILL.md` — detect language, call appropriate linter tool, format output
6. Test with JavaScript and Python snippets containing known style violations
7. Document usage example, supported languages, and the hard dependency on linter binaries being installed

**Relevant Context:**
- ⚠️ Stretch goal — deprioritize if time is short; Tasks 1–5 take priority
- This task has a dependency on Task 5b's MCP server scaffold existing first
- ESLint and Pylint/Ruff must be installed in the environment for the tools to work — document this clearly
- Security anti-patterns should NOT be duplicated here — keep scope to style only
- See `docs/IDEAS.md` — "Code (Maybe?)" section for the team's original caution around this feature

---

### Task 7 — Mode + Orchestration Layer

**Status:** `[ ] pending`

**Intent:**
Wire all skills together into a coherent mode experience. Update the `custom_modes.yaml` to reference the completed skills, define routing logic (how does Bob decide which skill to apply to which artifact?), and ensure the mode's `customInstructions` and `whenToUse` accurately describe the full feature set.

**Expected Outcomes:**
- `.bob/custom_modes.yaml` updated to reflect all completed skills and their trigger conditions
- `customInstructions` revised to describe routing logic: artifact type detection → skill selection
- `whenToUse` updated with trigger phrases for all new skills
- Mode works end-to-end: a user can open the repo, the mode activates, and all skills are accessible

**Todo List:**
1. Collect the completed SKILL.md files from Tasks 1–6
2. Update `customInstructions` in `.bob/custom_modes.yaml` to describe the routing logic
3. Update `whenToUse` to include trigger phrases for all skills
4. Update `README.md` with full install instructions and a skill reference table
5. Do an end-to-end smoke test: invoke each skill from within the mode and verify output format consistency
6. Ensure all skills use the same findings format (severity / location / description / fix + confidence score + verdict)

**Relevant Context:**
- `.bob/custom_modes.yaml` is the active mode definition — changes here are live immediately when the repo is open in Bob
- The existing mode already has `groups: [read, edit, mcp, skill, subagent]` — verify all required groups are still present after updates
- This task cannot start until at least a majority of Tasks 1–6 are complete

---

### Task 8 — Demo + Submission Packaging

**Status:** `[ ] pending`

**Intent:**
Produce all required submission artifacts as defined in `docs/SUBMISSION_REQUIREMENTS.md`: demo video, prompt documentation, problem statement, and the final submission zip. This is a full-team task done at the end.

**Expected Outcomes:**
- Demo video (≤5 minutes) recorded showing the mode in action across at least 3 artifact types
- Problem statement document written covering: the problem, why it matters, and the proposed solution
- Prompt documentation showing key prompts and usage examples for each skill
- Final zip assembled and posted to the Bob-A-Thon repo

**Todo List:**
1. Write the problem statement (`docs/PROBLEM_STATEMENT.md`): problem, why it matters, solution overview
2. Compile prompt documentation (`docs/PROMPTS.md`): one section per skill with example invocation and output
3. Record the demo video — suggested flow: show a flawed artifact, run Bob Council, run DeLLMify, run Requirements Cross-Check, show the confidence score, show the cleaned output
4. Assemble the final zip with all required materials
5. Ensure all team members have submitted individual feedback via the Bob feedback page (required to unlock submission)

**Relevant Context:**
- `docs/SUBMISSION_REQUIREMENTS.md` lists all mandatory submission components — treat it as the checklist
- The demo should foreground the Requirements Cross-Check as the highest product-value feature
- Bob Council is the most visually impressive feature — lead with it in the video
- This task cannot start until Task 7 (Mode + Orchestration) is complete

---

## Dependency Overview

```
Tasks 1–5a (skills)  ──►  Task 7 (mode + orchestration)  ──►  Task 8 (demo + submission)
Task 5b (MCP + skill) ──►  Task 7
Task 6  (MCP + skill) ──►  Task 7   [stretch — Task 6 depends on Task 5b MCP scaffold]
         │
         └── Tasks 1–5a are fully parallel and independent of each other
             Task 5b adds an MCP server; Task 6 extends that same MCP server
             Task 6 cannot start until Task 5b's mcp-server/ scaffold exists
             Task 6 is a stretch goal — skip if time is short
```
