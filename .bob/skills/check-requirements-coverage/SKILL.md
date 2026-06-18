---
name: check-requirements-coverage
description: Use when validating whether an artifact covers all requirements and acceptance criteria defined in spec.md. Produces a per-requirement verdict table with covered, partial, and missing findings.
---

# Check Requirements Coverage — Requirements Validator

You are invoked by the requirements-cross-check orchestrator. Your job is one thing only:
systematically check every requirement and acceptance criterion in `spec.md` against the
provided artifact and return structured findings. Do not generate a final report — that is
the job of the generate-validation-report skill.

## Step 1 — Read spec.md

Use `read_file` to read `spec.md` in full.

Extract and number every item from these sections:
- Requirements (numbered list)
- Acceptance Criteria (checklist items)
- Testing Scenarios (if present)

If `spec.md` is empty or only contains template placeholder text, stop and tell the user:
"Your `spec.md` appears to be empty or still contains only the template placeholders.
Please fill it in with your actual requirements before running the validation."

## Step 2 — Read the artifact

If the artifact was provided as a file path, use `read_file` to load it.
If the artifact was pasted as text, use it directly.

Note the artifact type (spec, plan, tasks, code, PR diff, free-form text) so it can be
included in the report.

## Step 3 — Check each requirement

For every requirement and acceptance criterion extracted in Step 1, scan the artifact and
assign a verdict:

- ✅ **Covered** — the artifact clearly and fully addresses this requirement. There is
  explicit evidence — not just a passing mention.
- ⚠️ **Partial** — the artifact references this requirement but does not fully address it.
  Something is vague, incomplete, or missing a specific value or constraint.
- ❌ **Missing** — there is no evidence in the artifact that this requirement has been
  considered or addressed.

For each verdict, note:
- Where in the artifact the evidence was found (section, line, or description)
- What is missing or incomplete (for Partial and Missing verdicts)

Be strict. A vague mention does not count as Covered — it counts as Partial.

## Step 4 — Return structured findings

Return your findings in this exact format so the orchestrator and report skill can use them:

```
REQUIREMENTS COVERAGE FINDINGS

Artifact: [name or type]
Source: spec.md

| # | Requirement | Verdict | Evidence / Notes |
|---|---|---|---|
| 1 | [requirement text] | ✅ Covered | [where it is addressed] |
| 2 | [requirement text] | ⚠️ Partial | [what is missing or vague] |
| 3 | [requirement text] | ❌ Missing | [no evidence found] |

ACCEPTANCE CRITERIA

| # | Criterion | Verdict | Evidence / Notes |
|---|---|---|---|
| 1 | [criterion text] | ✅ Covered | [where it is satisfied] |
| 2 | [criterion text] | ❌ Missing | [not addressed] |

SUMMARY
- Total requirements: X
- Fully covered: X
- Partial: X
- Missing: X
- Coverage score: X% (fully covered / total)
```

Do not add commentary, suggestions, or a fix list — that is assembled by the report skill.
Return only the structured findings above.
