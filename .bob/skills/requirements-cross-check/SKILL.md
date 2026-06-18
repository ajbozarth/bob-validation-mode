---
name: requirements-cross-check
description: Use when the user wants to validate an artifact against requirements or compliance rules — cross-checks a spec, plan, tasks, or code against spec.md and constitution.md, flags missing coverage and violations, and generates a structured report. Trigger phrases include "validate against requirements", "cross-check this against the spec", "does this meet the requirements", "requirements cross-check", "check compliance".
---

# Requirements Cross-Check — Orchestrator

You are the entry point for the requirements cross-check workflow. Your job is to detect what
is available in the workspace, route to the correct sub-skill, and coordinate the full validation
pipeline. Do not perform validation yourself — delegate to the focused sub-skills.

## Step 1 — Scan the workspace for foundational files

Use `glob` or `list_files` to check whether the following files exist anywhere in the workspace:
- `spec.md`
- `constitution.md`
- `plan.md`

Note which files are present and which are missing.

## Step 2 — Route based on what is missing

**If any of the three files are missing:**
- Tell the user which files are missing and why each one matters for validation
- Invoke the `setup-project-docs` skill to create templates for the missing files
- Wait for the user to confirm they have filled in the templates before continuing
- Once confirmed, re-scan to verify the files now exist, then proceed to Step 3

**If all three files are present:**
- Proceed directly to Step 3

## Step 3 — Identify the artifact to validate

Ask the user: "What artifact would you like to validate? You can paste it directly, point me to
a file, or I can validate the current plan/tasks in the workspace."

Wait for the user to provide the artifact before continuing.

## Step 4 — Run requirements coverage check

Invoke the `check-requirements-coverage` skill, passing:
- The artifact provided by the user
- The location of `spec.md`

Collect the structured findings (per-requirement verdicts) before moving to Step 5.

## Step 5 — Run constitution compliance check

Invoke the `check-constitution-compliance` skill, passing:
- The artifact provided by the user
- The location of `constitution.md`

Collect the structured findings (per-guardrail severity ratings) before moving to Step 6.

## Step 6 — Generate the validation report

Invoke the `generate-validation-report` skill, passing:
- The artifact name and type
- Requirements coverage findings from Step 4
- Constitution compliance findings from Step 5

The report skill will write `validation-report.md` to the workspace and display the report in chat.

## Step 7 — Close out

After the report is displayed, summarise the top 3 actions the user should take next based on
the fix priority list. Keep it to 3 bullet points — direct, no filler.
