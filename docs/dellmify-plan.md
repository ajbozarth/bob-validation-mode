# DeLLMify Pass — Task 2 Implementation Plan

## Overview

**Goal:** Build a DeLLMify skill that detects and removes LLM-like language patterns from any text artifact, improving directness and human readability. The skill auto-rewrites flagged phrases and provides before/after scores showing how "LLM-dense" the input was.

**Scope:** A single `.bob/skills/dellmify/SKILL.md` file that:
- Accepts file paths (one or more) OR inline text pasted in chat
- Automatically rewrites flagged LLM-like phrases with direct, human alternatives
- Produces a before/after score (0–100, where 100 is fully human-sounding)
- Reports what changes were made
- Skips code blocks and inline code entirely (prose/natural language only)

**Non-goals:**
- No external MCP tools — this is a pure reasoning-based skill
- No governing document-specific logic (that's Requirements Cross-Check's job)
- No interactive confirmation flow — the skill auto-rewrites and reports changes

**Delivery artifact:** `.bob/skills/dellmify/SKILL.md`

---

## Design Decisions

### Input Modes
The skill handles two input modes:
1. **File mode:** User points at one or more file paths → skill reads, rewrites in place, reports changes
2. **Inline mode:** User pastes text directly in chat → skill returns cleaned version (no file writes)

### Rewrite Behavior
- **Auto-rewrite:** The skill replaces flagged phrases without asking for confirmation
- **Scope:** Prose and natural language only — skip fenced code blocks (` ```...``` `), inline code (`` `...` ``), and code comments
- **Output when writing files:** Before/after score + summary of changes made
- **Output for inline text:** Cleaned version + before/after score + change summary

### Score Calculation
- **0–100 numeric score** where 100 = fully human-sounding, 0 = maximum LLM density
- Calculated **before** and **after** the rewrite
- Score formula should account for both the count of flagged phrases and their severity (hedging words weigh more than filler phrases)

### Pattern List
A curated list of LLM-like phrases, hedges, and filler patterns baked directly into the SKILL.md. The list should be organized by category for clarity:
- **Hedging phrases** (e.g., "It's worth noting that", "It's important to consider")
- **Deferential language** (e.g., "Certainly!", "Of course", "Absolutely")
- **Filler words** (e.g., "essentially", "actually", "basically")
- **AI self-references** (e.g., "As an AI", "As a language model")
- **Overly formal constructions** (e.g., "In order to", "With regard to", "In terms of")

---

## Sub-Tasks

---

### Sub-Task 1: Research and Compile LLM-Like Phrase Patterns

**Status:** `[ ] pending`

**Intent:**
Build a comprehensive, categorized list of LLM-like language patterns that the skill will detect and rewrite. This list is the heart of the DeLLMify skill — it defines what "LLM-like" means in practice. The list should be opinionated and grounded in real examples of LLM output, not speculative.

**Expected Outcomes:**
- A categorized list of at least 50 LLM-like phrases across 5+ categories
- Each pattern includes the flagged phrase and a direct human alternative
- Categories are distinct (no overlap between hedging and filler, for example)
- The list can be expanded later without reworking the skill logic

**Todo List:**
1. Review real Bob output from `README.md`, `docs/PLAN.md`, and `docs/IDEAS.md` in this repo for concrete examples
2. Identify common categories: hedging, deferential, filler, AI self-references, overly formal, meta-commentary
3. For each category, list 8–12 specific phrases with direct alternatives
4. Ensure patterns are phrase-level, not word-level (e.g., "It's worth noting that" not just "worth")
5. Document edge cases: what about technical prose vs. casual prose? Should tone matter?
6. Write the pattern list into a structured format ready to be embedded in SKILL.md

**Relevant Context:**
- `docs/IDEAS.md` lines 55–57 define the original DeLLMify concept
- The existing mode (`bob-validation`) already produces structured outputs — this skill should match that convention
- Real repo docs (`README.md`, `docs/PLAN.md`) are available as source material for pattern mining
- The pattern list will be directly embedded in SKILL.md (not a separate file)

---

### Sub-Task 2: Define Score Calculation Logic

**Status:** `[ ] pending`

**Intent:**
Define how the before/after score (0–100) is calculated from the text and detected patterns. The score should be deterministic, meaningful, and easy to interpret. A text with zero flagged phrases should score 100; a text riddled with LLM-like language should score low.

**Expected Outcomes:**
- A clear formula for calculating the score: `f(flagged_count, text_length, severity_weights)`
- Severity weights assigned to each pattern category (hedging > filler > deferential, for example)
- The formula produces intuitive scores across a range of test cases
- The logic is simple enough to describe in prose instructions (no external script needed)

**Todo List:**
1. Decide the scoring dimensions: count of flagged phrases, text length (word count or sentence count?), and severity per category
2. Assign severity weights: how much should hedging count vs. filler vs. AI self-references?
3. Draft a formula: `score = 100 - (weighted_flagged_count / text_length) * scaling_factor`
4. Test the formula on sample texts with known characteristics (high/medium/low LLM density)
5. Adjust scaling factor so the score range (0–100) is well-distributed
6. Write the formula into the SKILL.md instructions so Bob can calculate it consistently

**Relevant Context:**
- The mode's `customInstructions` already reference a 0–100 confidence score — this score should feel consistent with that convention
- The score is shown **before** and **after** the rewrite, so users can see the improvement
- The formula should work for both long documents (README) and short snippets (inline text)
- If the formula is too complex to describe in prose, consider whether a supporting script is needed (but prefer keeping it in prose if possible)

---

### Sub-Task 3: Write `skills/dellmify/SKILL.md` — Frontmatter and Structure

**Status:** `[ ] pending`

**Intent:**
Scaffold the SKILL.md file with the correct frontmatter, name, and overall structure. The frontmatter defines when Bob auto-invokes the skill, and the body provides the step-by-step instructions Bob follows when the skill activates.

**Expected Outcomes:**
- `.bob/skills/dellmify/SKILL.md` created with valid frontmatter
- `name: dellmify` (matching the directory name)
- `description:` field written with concrete trigger phrases (e.g., "Use when the user wants to clean up LLM-like language, remove hedging phrases, or improve the directness of a document")
- Body structure outlined: input handling → pattern detection → rewriting → scoring → output formatting
- The file validates against the SKILL.md schema (lowercase name, no underscores, max 64 chars)

**Todo List:**
1. Create the directory `.bob/skills/dellmify/` if it doesn't exist
2. Write the frontmatter with `name: dellmify` and a description that includes trigger phrases like "DeLLMify", "remove hedging", "clean up LLM language", "make this more direct"
3. Draft the body structure as a numbered step list:
   - Step 1: Determine input mode (file paths vs. inline text)
   - Step 2: Extract text and skip code blocks/inline code
   - Step 3: Detect flagged phrases using the pattern list
   - Step 4: Calculate before-score
   - Step 5: Rewrite flagged phrases with human alternatives
   - Step 6: Calculate after-score
   - Step 7: Output results (change summary + scores)
4. Confirm the directory name matches the regex: `^[a-z0-9]+(-[a-z0-9]+)*$` (it does: `dellmify`)
5. Save the file and test that it appears in Bob's skill list (requires starting a new task)

**Relevant Context:**
- See the `create-skill` skill instructions (already loaded) for the SKILL.md schema
- The directory name must be lowercase, no underscores — `dellmify` is valid
- The `description` field is the most important — it drives auto-activation when the user's phrasing matches
- Bob has `read`, `edit`, `skill` groups in the mode — the skill can use `read_file`, `write_file`, and `apply_diff`

---

### Sub-Task 4: Embed the Pattern List into SKILL.md

**Status:** `[ ] pending`

**Intent:**
Take the curated pattern list from Sub-Task 1 and embed it directly into the SKILL.md body as a reference section. Bob will use this list every time the skill runs to detect and rewrite LLM-like language.

**Expected Outcomes:**
- The pattern list is formatted as a Markdown table or structured list inside SKILL.md
- Each entry shows: flagged phrase → human alternative → category → severity weight
- The list is easy for Bob to parse and apply during the rewrite step
- The list can be expanded later by editing the SKILL.md without changing the logic

**Todo List:**
1. Format the pattern list from Sub-Task 1 as a Markdown table with columns: Phrase | Alternative | Category | Weight
2. Embed the table into the SKILL.md body under a `## LLM-Like Phrase Patterns` section
3. Add a note at the top of the pattern section: "Check the input text against these patterns. Flag any exact or near-exact matches."
4. Ensure the patterns are specific enough to avoid false positives (e.g., "certainly" by itself might be legitimate; "Certainly!" is LLM-like)
5. Review the final embedded list for completeness — does it cover the major LLM-language categories?

**Relevant Context:**
- The pattern list is the core detection logic — the rest of the skill is orchestration around this list
- Near-exact matches should be supported (case-insensitive, ignoring punctuation)
- The list should include 50+ patterns but stay under 200 lines to keep the SKILL.md readable
- If the list grows beyond 200 lines in the future, consider extracting it to a separate file and instructing Bob to read it (but start with it embedded for simplicity)

---

### Sub-Task 5: Write Rewriting and Scoring Instructions

**Status:** `[ ] pending`

**Intent:**
Complete the SKILL.md body with detailed step-by-step instructions for detecting patterns, rewriting text, calculating scores, and formatting output. This is the procedural core of the skill.

**Expected Outcomes:**
- Step 1 (input handling): Bob determines whether the user provided file paths or inline text
- Step 2 (text extraction): Bob reads the file(s) or uses the inline text; skips code blocks and inline code
- Step 3 (detection): Bob flags all occurrences of patterns from the embedded list
- Step 4 (before-score): Bob calculates the score using the formula from Sub-Task 2
- Step 5 (rewriting): Bob replaces each flagged phrase with its human alternative
- Step 6 (after-score): Bob recalculates the score on the cleaned text
- Step 7 (output): Bob reports changes made, before/after scores, and writes files if applicable

**Todo List:**
1. Write Step 1 instructions: use `read_file` if file paths provided, otherwise treat the user's message as inline text
2. Write Step 2 instructions: extract prose sections; skip fenced code blocks (` ```...``` `) and inline code (`` `...` ``)
3. Write Step 3 instructions: scan the text for patterns from the embedded list; flag each occurrence with location (line number or paragraph)
4. Write Step 4 instructions: calculate before-score using the formula from Sub-Task 2 (include the formula inline)
5. Write Step 5 instructions: replace each flagged phrase with its alternative from the pattern table
6. Write Step 6 instructions: recalculate the score on the cleaned text
7. Write Step 7 instructions: format the output as a structured report (see output format below)
8. Test the instructions by invoking the skill on `README.md` in this repo

**Output Format (to be included in SKILL.md):**
```
## DeLLMify Results

**Before Score:** [0-100]  
**After Score:** [0-100]

### Changes Made
- Line [X]: "[original phrase]" → "[cleaned phrase]" (category: [hedging/filler/etc])
- Line [Y]: "[original phrase]" → "[cleaned phrase]" (category: ...)

[If file mode: "Files updated in place: [file1, file2, ...]"]
[If inline mode: "[Cleaned text shown below]"]
```

**Relevant Context:**
- Bob has access to `read_file`, `write_file`, and `apply_diff` in the mode's `edit` group
- The skill should use `apply_diff` for in-place file edits (more surgical than full rewrites)
- The output format should match the mode's standard findings format: severity / location / description / fix
- Skip fenced code blocks by detecting ` ```...``` ` boundaries and inline code by detecting `` `...` ``

---

### Sub-Task 6: Test Against Repo Docs

**Status:** `[ ] pending`

**Intent:**
Validate the completed skill by running it against real documents in this repository. The test should confirm that the skill correctly detects patterns, rewrites them, calculates scores, and formats output — and that it skips code blocks as expected. **Test runs must not commit any edits to repo files** — testing is observation-only, with file rewrites reverted or avoided during the test phase.

**Expected Outcomes:**
- The skill successfully processes `README.md` and flags/rewrites at least a few LLM-like phrases
- The skill successfully processes one or more files in `docs/` and produces meaningful before/after scores
- The skill skips code blocks in test files without breaking them
- The output format is consistent with the standard findings format defined in the mode
- Any bugs or edge cases discovered during testing are fixed before marking the task complete
- No test-driven edits are committed to the repo

**Todo List:**
1. Start a new Bob task/chat to ensure the skill is loaded (skills only appear after the task they were created in)
2. **Test inline mode first** (safest — no file writes): paste a paragraph of LLM-like text directly in chat and ask Bob to clean it up; verify the output format and score calculation
3. **Test file mode in read-only fashion**: invoke the skill on `README.md` with an instruction to report changes but not write them, or review the proposed diff before accepting it
4. Invoke the skill on files in `docs/` (e.g., `docs/IDEAS.md`, `docs/PLAN.md`) in the same read-only manner — check score calculation on longer documents
5. Test code-skipping: create a temporary scratch file (e.g., `docs/dellmify-test-scratch.md`) with fenced code blocks containing "certainly" or "It's worth noting" inside the code — verify the skill does NOT flag those phrases, then delete the scratch file
6. Fix any issues (incorrect pattern matching, broken score calculation, output formatting inconsistencies)
7. **If test coverage is insufficient** (e.g., no real LLM-like phrases found in repo docs), source an external document — copy a paragraph of real LLM output into an inline test rather than committing a test fixture to the repo
8. Document the test results and any edge cases discovered; do a final `git status` check to confirm no unintended file modifications are staged

**Relevant Context:**
- `README.md` is ~75 lines — short enough for a quick first test
- `docs/PLAN.md` is 319 lines — long enough to test score calculation at scale
- `docs/IDEAS.md` is 92 lines — includes both prose and bullet lists, good structural variety
- The scratch file for code-block testing (`docs/dellmify-test-scratch.md`) should be created and deleted within the same test session — do not commit it
- The skill should work on the first invocation after being created — if it doesn't appear, check the directory name (must be lowercase, no underscores)
- Edge cases to watch for: pattern false positives, code block detection failures, score calculation bugs when text is very short or very long

---

### Sub-Task 7: Document Usage in SKILL.md

**Status:** `[ ] pending`

**Intent:**
Add a usage examples section to the SKILL.md so users (and Bob) know how to invoke the skill and what to expect. The examples should cover both file mode and inline mode.

**Expected Outcomes:**
- A `## Usage Examples` section added to the bottom of SKILL.md
- At least two examples shown: one for file mode, one for inline mode
- Each example includes the user prompt and a snippet of the expected output
- The examples are generic (not hardcoded to specific repo files) so the skill is reusable

**Todo List:**
1. Add a `## Usage Examples` section to the bottom of SKILL.md
2. Write Example 1 (file mode): user says "DeLLMify the README" → show expected output format
3. Write Example 2 (inline mode): user pastes a paragraph with hedging phrases → show cleaned output
4. Add a note about the before/after score: "A score of 85+ indicates mostly human-sounding text; below 70 suggests significant LLM-language density"
5. Add a note about code blocks: "The skill automatically skips code blocks and inline code — only prose is processed"
6. Review the examples for clarity — would a new user understand how to invoke the skill after reading them?

**Relevant Context:**
- The usage examples should NOT reference `bob-chat-history/` files (those are session transcripts, not real docs)
- Generic examples like "DeLLMify my-doc.md" or "Clean up this text: [paste]" are better than repo-specific paths
- The `create-skill` skill instructions recommend including usage examples in the SKILL.md body
- Keep the examples short — 3-5 lines each

---

## Dependency Overview

```
Sub-Task 1 (pattern list) ──► Sub-Task 4 (embed patterns into SKILL.md)
Sub-Task 2 (score logic)  ──► Sub-Task 5 (rewriting instructions)
Sub-Task 3 (scaffold)     ──► Sub-Task 4, Sub-Task 5
Sub-Tasks 4 + 5           ──► Sub-Task 6 (testing)
Sub-Task 6                ──► Sub-Task 7 (document usage)

Sub-Tasks 1, 2, 3 can run in parallel.
Sub-Task 6 cannot start until Sub-Tasks 4 and 5 are complete.
Sub-Task 7 is final polish and can only run after testing is done.
```

---

## Integration Notes

This task feeds into **Task 7 (Mode + Orchestration)**:
- Task 7 will update `.bob/custom_modes.yaml` to reference the DeLLMify skill in `whenToUse` trigger phrases
- Task 7 will ensure the DeLLMify output format matches the mode's standard findings format
- The `customInstructions` in the mode already reference a confidence score (0–100) — the DeLLMify score aligns with that convention

The DeLLMify skill is **independent** of the other skills (Bob Council, Confidence Score, Requirements Cross-Check, Markdown Validator) and can be built in parallel with them.

---

## Open Questions for Later

- Should the pattern list be expanded to include domain-specific jargon (e.g., corporate-speak, academic hedging)?
- Should the skill support a "conservative" vs. "aggressive" rewriting mode, where conservative only flags high-severity patterns?
- Should the skill produce a machine-readable JSON output in addition to the human-readable report?

These are out of scope for the hackathon but worth noting for future iterations.
