---
name: dellmify
description: Use when the user wants to DeLLMify a document, remove hedging or filler phrases, clean up LLM-like language, make text more direct, or improve the human readability of a document or passage.
---

# DeLLMify

Remove LLM-like language patterns from text and replace them with direct, human alternatives. Calculate a before/after score showing how much the text improved.

## Step 1 — Determine Input Mode

Check the user's message:

- **File mode:** The user referenced one or more file paths (e.g. "DeLLMify README.md" or "clean up docs/PLAN.md"). Use `read_file` to load each file. Process and rewrite each file in place using `apply_diff`.
- **Inline mode:** The user pasted text directly in chat with no file path. Use the pasted text as the input. Return the cleaned version in the response — do not write any files.

If the user referenced files but also pasted text, treat the files as the primary input and ignore the pasted text.

## Step 2 — Extract Prose Sections

Before scanning for patterns, identify and skip all non-prose regions:

- **Fenced code blocks:** Any content between opening ` ``` ` and closing ` ``` ` fences — skip entirely regardless of language tag.
- **Inline code:** Any content wrapped in single backticks `` `like this` `` — skip entirely.
- **YAML/TOML frontmatter:** Any `---`-delimited block at the very top of a Markdown file — skip entirely.

Only scan the remaining prose text for LLM-like patterns. Do not modify anything inside skipped regions.

**Important:** Text inside double-quotes `"like this"` in prose is still prose — do not skip it. Only backtick-delimited spans and fenced code blocks are excluded.

## Step 3 — Detect Flagged Phrases

Scan the prose text against the pattern table in the **LLM-Like Phrase Patterns** section below. For each match:

- Record the flagged phrase, its location (line number or surrounding sentence), the human alternative, and the severity weight.
- Matching is case-insensitive. Strip leading/trailing punctuation before matching (e.g. "Certainly!" matches the "Certainly" entry).
- Flag complete phrase matches only — do not flag substrings. "notable" should not trigger the "It's worth noting" pattern.
- If the same phrase appears multiple times, record each occurrence separately.

**Em-dash density check:** After scanning for phrase patterns, count the total number of em dashes (`—`) in the prose sections. If the count exceeds **1 em dash per 100 words** of prose, flag the overuse: report the count and total prose word count, and recommend reviewing the highest-density sentences for replacement with commas, semicolons, colons, or parentheses as appropriate. Do not automatically rewrite em dashes — flag them for human review only. Add a single `Em-dash overuse` entry to the change list with weight **1** when the threshold is exceeded.

Build a change list: `[(line, original_phrase, replacement, category, weight), ...]`

## Step 4 — Calculate Before-Score

Use the change list and the prose word count to calculate the before-score:

```
weighted_count = sum of severity weights for all flagged occurrences
prose_word_count = total word count of prose-only sections (excluding skipped regions)
before_score = max(0, 100 - round((weighted_count / prose_word_count) * 500))
```

Cap the score at 0 (floor) and 100 (ceiling). A text with zero flagged phrases scores 100.

**Severity weights by category:**
- AI self-reference: **3**
- Hedging: **3**
- Deferential opener: **3**
- Meta-commentary: **2**
- Overly formal: **2**
- Cliché/Hyperbole: **2**
- Filler word/phrase: **1**

## Step 5 — Rewrite the Text

Apply every replacement from the change list:

- Replace each flagged phrase with its human alternative from the pattern table.
- Preserve surrounding punctuation, capitalisation context, and sentence structure.
- If a sentence becomes grammatically awkward after replacement, minimally rephrase that sentence only — do not rewrite surrounding content.
- Do not touch code blocks, inline code, or frontmatter (from Step 2).

**File mode:** Use `apply_diff` to write the changes back to the file in place. Apply all replacements for a given file in a single `apply_diff` call where possible.

**Inline mode:** Hold the cleaned text in memory — output it in Step 7.

## Step 6 — Calculate After-Score

Re-scan the rewritten prose against the pattern table. Calculate the after-score using the same formula as Step 4. In most cases the after-score should be 100 (all patterns removed), but a small number of near-miss phrases that were not exact matches may remain.

## Step 7 — Output Results

Always output the following report, regardless of input mode:

---

```
## DeLLMify Results

**Before Score:** [before_score]/100
**After Score:**  [after_score]/100

### Changes Made ([N] replacements)

| Line | Original | Replacement | Category |
|------|----------|-------------|----------|
| [L]  | "[phrase]" | "[alternative]" | [category] |
...

[If no changes: "No LLM-like patterns detected. Score: 100/100"]
```

For **inline mode**, append the full cleaned text after the report under a `### Cleaned Text` heading.

For **file mode**, list the files updated: `Files rewritten in place: [file1, file2, ...]`

---

## LLM-Like Phrase Patterns

Match against these patterns (case-insensitive, strip trailing punctuation before matching).

### Category: AI Self-Reference (weight 3)
Phrases where the author frames themselves as an AI or language model.

| Flagged Phrase | Human Alternative |
|---|---|
| As an AI language model | (remove entirely) |
| As an AI | (remove entirely) |
| As a large language model | (remove entirely) |
| As a language model | (remove entirely) |
| I'm just an AI | (remove entirely) |
| I don't have personal opinions | (remove the sentence) |
| I don't have feelings | (remove the sentence) |
| I cannot browse the internet | (remove the sentence) |
| My knowledge cutoff | My training data ends |
| As of my last update | (remove — restate the fact directly) |
| Based on my training data | (remove — state the claim directly) |

### Category: Hedging (weight 3)
Phrases that avoid commitment or soften a claim unnecessarily.

| Flagged Phrase | Human Alternative |
|---|---|
| It's worth noting that | Note: |
| It is worth noting that | Note: |
| It's important to note that | Note: |
| It is important to note that | Note: |
| It's worth mentioning that | (remove — state the point directly) |
| It is worth mentioning that | (remove — state the point directly) |
| It's important to keep in mind that | Keep in mind: |
| It is important to keep in mind that | Keep in mind: |
| It should be noted that | Note: |
| One could argue that | (remove — state the argument directly) |
| It could be argued that | (remove — state the argument directly) |
| It's possible that | (remove — state the possibility directly) |
| It is possible that | (remove — state the possibility directly) |
| It's likely that | Likely, |
| It is likely that | Likely, |
| There's a chance that | (remove — state the uncertainty directly) |
| It may be the case that | (remove — state the claim directly) |
| It might be worth considering | Consider |

### Category: Deferential Opener (weight 3)
Phrases that open a response with unnecessary agreement or enthusiasm.

| Flagged Phrase | Human Alternative |
|---|---|
| Certainly! | (remove) |
| Certainly, | (remove) |
| Absolutely! | (remove) |
| Absolutely, | (remove) |
| Of course! | (remove) |
| Of course, | (remove) |
| Sure! | (remove) |
| Sure, | (remove) |
| Great question! | (remove) |
| That's a great question | (remove) |
| That's an excellent question | (remove) |
| Excellent question! | (remove) |
| Great point! | (remove) |
| I'd be happy to | (remove — start with the action) |
| I'd be glad to | (remove — start with the action) |
| I'm happy to help | (remove — start with the action) |
| Happy to help! | (remove) |
| No problem! | (remove) |
| Of course, I can help with that | (remove — start with the action) |

### Category: Meta-Commentary (weight 2)
Phrases where the author comments on what they are about to do rather than doing it.

| Flagged Phrase | Human Alternative |
|---|---|
| Let me explain | (remove — just explain) |
| Let me clarify | (remove — just clarify) |
| Allow me to explain | (remove — just explain) |
| Allow me to clarify | (remove — just clarify) |
| Let me break this down | (remove — just break it down) |
| I'll walk you through | (remove — just walk through it) |
| Let's dive into | (remove — just start) |
| Let's explore | (remove — just start) |
| In this response, I will | (remove — just do it) |
| In this section, we will | (remove — just do it) |
| I'm going to explain | (remove — just explain) |
| I will now explain | (remove — just explain) |
| To summarize | In summary, |
| To summarize what we've covered | In summary, |
| Let me summarize | In summary, |
| In conclusion, | (remove — just state the conclusion) |
| To conclude, | (remove — just state the conclusion) |
| As we can see | (remove — state the observation directly) |
| As you can see | (remove — state the observation directly) |
| As mentioned earlier | (remove — state the point directly) |
| As previously mentioned | (remove — state the point directly) |
| As noted above | (remove — state the point directly) |

### Category: Overly Formal (weight 2)
Unnecessarily bureaucratic constructions that add length without adding meaning.

| Flagged Phrase | Human Alternative |
|---|---|
| In order to | To |
| In order for | For |
| With regard to | On |
| With regards to | On |
| In regards to | On |
| In terms of | For / On (pick the shorter fit) |
| For the purposes of | For |
| With the aim of | To |
| With the goal of | To |
| In the context of | In |
| In the event that | If |
| In the case that | If |
| In the situation where | If |
| Due to the fact that | Because |
| Owing to the fact that | Because |
| Given the fact that | Given that |
| At this point in time | Now |
| At the present time | Now |
| In a timely manner | Promptly |
| On a regular basis | Regularly |
| In close proximity to | Near |
| A large number of | Many |
| A significant number of | Many |
| A majority of | Most |
| The majority of | Most |
| It is recommended that | (restate as a direct recommendation) |
| It is suggested that | (restate as a direct suggestion) |
| It is advised that | (restate as direct advice) |

### Category: Cliché/Hyperbole (weight 2)
Grandiose or dramatic framings that LLMs reach for but human writers avoid.

| Flagged Phrase | Human Alternative |
|---|---|
| the heart of | the core of |
| the cornerstone of | the foundation of |
| flagship | primary |
| game-changing | (remove or restate the specific benefit) |
| groundbreaking | (remove or restate the specific benefit) |
| revolutionary | (remove or restate the specific benefit) |
| transformative | (remove or restate the specific benefit) |
| cutting-edge | (remove or restate the specific capability) |
| state-of-the-art | (remove or restate the specific capability) |
| seamlessly | (remove) |
| robust | (remove or restate the specific quality) |
| comprehensive | (remove) |
| human readability | readability |

### Category: Filler Word/Phrase (weight 1)
Words and short phrases that add length without adding meaning.

| Flagged Phrase | Human Alternative |
|---|---|
| essentially | (remove) |
| basically | (remove) |
| fundamentally | (remove) |
| ultimately | (remove, or keep only if it genuinely means "in the end") |
| literally | (remove unless used for emphasis of fact) |
| obviously | (remove) |
| clearly | (remove) |
| naturally | (remove) |
| needless to say | (remove the phrase and the sentence if it adds nothing) |
| it goes without saying | (remove) |
| as a matter of fact | (remove) |
| in fact | (remove, or rephrase if adding a contrast) |
| indeed | (remove) |
| simply | (remove) |
| just | (remove unless it means "only" or "recently") |
| quite | (remove) |
| very | (remove — strengthen the word instead) |
| really | (remove) |
| truly | (remove) |
| actually | (remove unless correcting a misconception) |
| Please note that | Note: |
| Please be aware that | Note: |
| Please keep in mind that | Keep in mind: |
| It's crucial to | (restate as a direct statement) |
| It is crucial to | (restate as a direct statement) |
| It's essential to | (restate as a direct statement) |
| It is essential to | (restate as a direct statement) |

---

## Usage Examples

### Example 1 — File Mode

**User:** DeLLMify docs/PLAN.md

**Bob runs:** Reads `docs/PLAN.md`, detects patterns, rewrites in place, reports:

```
## DeLLMify Results

**Before Score:** 74/100
**After Score:**  98/100

### Changes Made (6 replacements)

| Line | Original | Replacement | Category |
|------|----------|-------------|----------|
| 12   | "In order to" | "To" | Overly formal |
| 34   | "It's worth noting that" | "Note:" | Hedging |
| 67   | "essentially" | (removed) | Filler |
| 89   | "In terms of" | "On" | Overly formal |
| 102  | "Certainly," | (removed) | Deferential opener |
| 145  | "As mentioned earlier" | (removed) | Meta-commentary |

Files rewritten in place: docs/PLAN.md
```

### Example 2 — Inline Mode

**User:** DeLLMify this: "Certainly! It's worth noting that, in order to achieve the best results, you should essentially focus on the core requirements."

**Bob returns:**

```
## DeLLMify Results

**Before Score:** 22/100
**After Score:**  100/100

### Changes Made (4 replacements)

| Line | Original | Replacement | Category |
|------|----------|-------------|----------|
| 1    | "Certainly!" | (removed) | Deferential opener |
| 1    | "It's worth noting that" | "Note:" | Hedging |
| 1    | "in order to" | "to" | Overly formal |
| 1    | "essentially" | (removed) | Filler |

### Cleaned Text

Note: to achieve the best results, focus on the core requirements.
```

### Notes

- A score of **90–100** indicates clean, direct prose.
- A score of **70–89** suggests moderate LLM-language density — worth a pass.
- A score **below 70** indicates heavy LLM-like language.
- The skill skips all code blocks and inline code — only prose is processed.
- Running on multiple files: "DeLLMify all markdown files in docs/" processes each file and reports a combined change table.
