---
name: generate-validation-report
description: Use when assembling the final requirements cross-check report from coverage and compliance findings. Formats findings into a structured report, calculates scores, writes validation-report.md to disk, and displays the result in chat.
---

# Generate Validation Report — Report Assembler

You are invoked by the requirements-cross-check orchestrator after both validation skills have
returned their findings. Your job is to assemble everything into a single structured report,
write it to disk, and display it in chat.

## Step 1 — Collect inputs

You will have received:
- Artifact name and type
- Requirements coverage findings from `check-requirements-coverage`
- Constitution compliance findings from `check-constitution-compliance`

If either set of findings is missing or malformed, state which is missing and stop. Do not
fabricate findings.

## Step 2 — Build the fix priority list

From the combined findings, extract all non-compliant items and sort them in this order:
1. ❌ Missing requirements (highest impact — feature gaps)
2. ❌ Constitution errors (hard violations — blockers)
3. ⚠️ Partial requirements (incomplete coverage)
4. ⚠️ Constitution warnings (standard deviations)
5. 💡 Constitution suggestions (best practice gaps)

For each item in the list, write one actionable fix in the format:
`[Severity] [Category] — what to fix and where`

## Step 3 — Calculate scores

**Coverage Score:**
- Formula: (fully covered requirements / total requirements) × 100
- Round to nearest whole number
- Express as: `X% (Y/Z requirements fully met)`

**Confidence Score (0–100):**
- Start at 100
- Subtract 15 for each ❌ Missing requirement
- Subtract 10 for each ❌ Constitution error
- Subtract 5 for each ⚠️ Partial requirement
- Subtract 3 for each ⚠️ Constitution warning
- Subtract 1 for each 💡 Suggestion
- Floor at 0

**Verdict (one line):**
- 90–100: "All requirements met and constitution compliant — ready to proceed."
- 70–89: "Minor gaps found — review warnings before proceeding."
- 50–69: "Moderate gaps — address errors and missing requirements before implementation."
- 0–49: "Significant gaps — must resolve errors and missing requirements before proceeding."

## Step 4 — Assemble the report

Assemble the full report using this exact structure:

```markdown
# Requirements Cross-Check Report

**Artifact:** [name and type]  
**Validated against:** spec.md · constitution.md  
**Date:** [today's date]

---

## Requirements Coverage

| # | Requirement | Verdict | Notes |
|---|---|---|---|
[one row per requirement from coverage findings]

| # | Acceptance Criterion | Verdict | Notes |
|---|---|---|---|
[one row per acceptance criterion from coverage findings]

**Coverage: X fully met · X partial · X missing**

---

## Constitution Compliance

### Tech Stack
| Severity | Guardrail | Finding |
|---|---|---|
[rows from compliance findings - tech stack section]

### Coding Standards
| Severity | Guardrail | Finding |
|---|---|---|
[rows from compliance findings - coding standards section]

### Testing Standards
| Severity | Guardrail | Finding |
|---|---|---|
[rows from compliance findings - testing standards section]

### Security & Compliance
| Severity | Guardrail | Finding |
|---|---|---|
[rows from compliance findings - security section]

### Architecture Decisions
| Severity | Guardrail | Finding |
|---|---|---|
[rows from compliance findings - ADR section]

---

## Fix Priority

[numbered list from Step 2, errors and missing first]

---

## Overall

| Metric | Score |
|---|---|
| Coverage Score | X% (Y/Z requirements fully met) |
| Confidence Score | X/100 |

**Verdict:** [one-line verdict from Step 3]
```

## Step 5 — Write validation-report.md

Use `write_file` to write the assembled report to `validation-report.md` in the workspace root.

Tell the user: "Report written to `validation-report.md`."

## Step 6 — Display the report in chat

Print the full report in chat after writing the file.

## Step 7 — Return control to orchestrator

Signal completion so the orchestrator can deliver the top 3 next actions to the user.
