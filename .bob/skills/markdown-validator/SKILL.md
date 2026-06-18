---
name: markdown-validator
description: Validate the structural and semantic correctness of a Markdown document. Checks heading hierarchy, broken links, malformed tables, unclosed code blocks, missing alt text, and other issues that degrade readability or rendering. Use when asked to validate, check, or review a Markdown file.
---

# Markdown Validator

Validate a Markdown document against a structural rule checklist. Report every violation as a structured finding. Do not rewrite or fix the document — annotate and report only.

## Step 1 — Determine Input

Check the user's message:

- **File mode:** The user referenced one or more file paths (e.g. "validate README.md"). Use `read_file` to load each file. Process each file independently.
- **Inline mode:** The user pasted Markdown text directly in chat. Use the pasted text as the input.

If the user referenced files but also pasted text, treat the files as the primary input.

## Step 2 — Identify Skip Regions

Before applying any rules, mark the following regions as non-prose — they are excluded from most structural checks:

- **Fenced code blocks:** Any content between ` ``` ` open and close fences — skip content inside, but the fences themselves are checked (see rules below).
- **Inline code:** Content wrapped in single backticks `` `like this` `` — skip.
- **YAML/TOML frontmatter:** A `---`-delimited block at the very top of the file — skip content inside, but validate it is properly closed.

Still apply these rules to skip regions where noted in the checklist below.

## Step 3 — Apply the Rule Checklist

Work through every rule in order. For each violation found, record a finding (see Step 4 for the finding format).

### Heading Rules

**H-1 — No skipped heading levels** (severity: `error`)
Heading levels must increment by one. A jump from H1 → H3 without an H2 is a violation. List every skip found.
- Location: the line where the out-of-sequence heading appears.

**H-2 — At most one H1** (severity: `warning`)
A document should have zero or one H1. If more than one H1 is found, report each occurrence after the first.
- Location: the line numbers of the extra H1 headings.

### Link Rules

**L-1 — No bare URLs** (severity: `warning`)
A URL appearing as plain text (e.g. `https://example.com`) without being wrapped in `[text](url)` syntax is a bare URL. Report each one.
- Exceptions: URLs inside fenced code blocks or inline code are skipped.
- Location: the line number where the bare URL appears.

**L-2 — No malformed link syntax** (severity: `error`)
A link is malformed if:
- The brackets or parentheses are unbalanced: `[text(url)` or `[text](` with no closing `)`.
- The href is empty: `[text]()`.
- The alt text of an image is empty: `![](url)` — flag this as both L-2 and A-1 below.

### Code Block Rules

**C-1 — Fenced code blocks must have a language tag** (severity: `suggestion`)
Every fenced code block should open with a language tag: ` ```python `, ` ```bash `, ` ```json `, etc. An opening ` ``` ` with no tag is a suggestion to add one.
- Location: the line number of the opening fence.

**C-2 — Fenced code blocks must be closed** (severity: `error`)
Every opening ` ``` ` fence must have a matching closing ` ``` ` fence. An unclosed fence is an error — it will break rendering for everything that follows it.
- Location: the line number of the unclosed opening fence.

### Table Rules

**T-1 — Table column counts must be consistent** (severity: `error`)
Every row in a table (header row, separator row, and data rows) must have the same number of `|`-delimited columns. Report the row number and expected vs actual column count.
- Location: the line number of the offending row.

**T-2 — Table separator row must be valid** (severity: `error`)
The row immediately after the header row in a table must contain only `-`, `:`, and `|` characters (plus optional whitespace). Any other content in that row is an error.
- Location: the line number of the separator row.

### Image Rules

**A-1 — Images must have non-empty alt text** (severity: `warning`)
Every `![alt](url)` tag must have a non-empty alt text value. `![](...) ` or `![  ](...)` (blank or whitespace-only) are violations.
- Location: the line number of the image tag.

### Whitespace and Structure Rules

**W-1 — No more than two consecutive blank lines** (severity: `suggestion`)
More than two consecutive blank lines in a row suggests accidental duplication. Report the starting line number and the count.

**W-2 — Frontmatter must be closed** (severity: `error`)
If a `---` block appears at the very top of the file (frontmatter), it must have a matching closing `---`. An unclosed frontmatter block will break rendering in most static site generators.
- Location: line 1 (the opening `---`).

### HTML Rules

**X-1 — Inline HTML tags must be closed** (severity: `warning`)
If inline HTML elements are used (e.g. `<details>`, `<summary>`, `<br>`), block-level tags must be closed (`</details>`, `</summary>`). Self-closing void elements (`<br>`, `<hr>`, `<img>`) are fine.
- Location: the line number of the unclosed opening tag.

## Step 4 — Record Findings

For every violation found in Step 3, record one finding using this format:

```
| Severity   | Location        | Rule | Description                                  | Recommended Fix                            |
|------------|-----------------|------|----------------------------------------------|--------------------------------------------|
| error      | Line 14         | H-1  | Heading jumps from H1 to H3 (H2 missing)     | Add an H2 heading between lines 12 and 14 |
| warning    | Line 27         | L-1  | Bare URL: https://example.com                | Wrap as [example.com](https://example.com) |
```

If no violations are found for a rule, do not include that rule in the table. If the document has zero violations, state that clearly instead of showing an empty table.

## Step 5 — Compute Confidence Score

After completing the checklist, assign a confidence score (0–100) reflecting how certain you are in the completeness and accuracy of the validation:

- **90–100:** Document is short (<200 lines), all rules checked fully, no ambiguous constructs.
- **70–89:** Document is medium length, most rules checked, one or two constructs were ambiguous.
- **50–69:** Document is long (>500 lines) or contains complex nesting that made some checks uncertain.
- **Below 50:** Very long document or highly unusual structure; findings may be incomplete.

## Step 6 — Produce Output

Emit findings in this order:

1. A one-line summary: `Validated: <filename or "inline input"> — <N> finding(s) across <M> rule(s).`
2. The findings table (Step 4). Omit the table if zero findings.
3. A blank line, then: `Confidence: <score>/100`
4. A one-line verdict:
   - Zero errors: `✓ Document is structurally sound.` (or note warnings/suggestions)
   - One or more errors: `✗ Document has structural errors that will break rendering.`

---

## Usage Example

**Input (inline mode):**

```markdown
# My Document

### Setup

See more at https://example.com

| Name | Age
|------|----|----|
| Alice | 30 |
| Bob  | 25 |

```python
code here
```

**Expected output:**

```
Validated: inline input — 4 finding(s) across 4 rule(s).

| Severity   | Location | Rule | Description                                | Recommended Fix                                     |
|------------|----------|------|--------------------------------------------|-----------------------------------------------------|
| error      | Line 3   | H-1  | Heading jumps from H1 to H3 (H2 missing)   | Add an H2 heading between lines 1 and 3             |
| warning    | Line 5   | L-1  | Bare URL: https://example.com              | Wrap as [example.com](https://example.com)          |
| error      | Line 7   | T-1  | Header row has 2 columns, separator has 3  | Remove the extra `|` from the separator row         |
| error      | Line 12  | C-2  | Unclosed fenced code block opened at line 12 | Add a closing ``` fence after the code block      |

Confidence: 92/100
✗ Document has structural errors that will break rendering.
```
