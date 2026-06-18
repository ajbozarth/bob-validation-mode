# Task 4 — Requirements Cross-Check Skill

**Branch:** `task/requirements-cross-check`  
**Assignee:** parshjadon  
**GitHub Issue:** #8

---

## Problem Statement

When Bob generates an artifact (a spec, plan, tasks breakdown, or code), there is currently no
systematic way to verify that:

1. Every requirement and acceptance criterion from the spec is actually addressed
2. The artifact complies with the project's "constitution" — the golden-path guardrails covering
   tech stack, coding standards, security, and compliance

Additionally, most users don't have these foundational documents set up at all — there is no
guided way to create them before validation can even begin.

---

## Proposed Solution

A set of **5 composable skills** that live inside the existing `🧪 Bob Validation` mode:

- One **orchestrator skill** that drives the full workflow
- One **setup skill** that detects missing files and creates templates with guidance
- Two **focused validation skills** (requirements coverage + constitution compliance)
- One **report generation skill** that assembles findings into a structured output

This gives the power of a multi-agent pattern (each skill does one focused job) without
needing a separate mode or complex agent orchestration.

---

## Architecture

```
User: "validate against requirements" or /requirements-cross-check
        │
        ▼
┌─────────────────────────────────────┐
│   requirements-cross-check          │  ← Orchestrator skill
│   Detects missing files, decides    │
│   setup vs validation path          │
└──────────────┬──────────────────────┘
               │
       ┌───────┴────────┐
       │                │
  Files missing?   Files present?
       │                │
       ▼                ▼
┌────────────┐   ┌──────────────────────────────┐
│  setup-    │   │  check-requirements-coverage  │
│  project-  │   │  (subagent 1)                 │
│  docs      │   ├──────────────────────────────┤
│            │   │  check-constitution-          │
│ Creates    │   │  compliance                   │
│ templates  │   │  (subagent 2)                 │
│ for any    │   ├──────────────────────────────┤
│ missing    │   │  generate-validation-report   │
│ files with │   │  (subagent 3)                 │
│ guidance   │   └──────────────────────────────┘
└────────────┘
```

---

## The 5 Skills

### 1. `requirements-cross-check` — Orchestrator

The entry point. Every other skill is called from here.

**Responsibilities:**
- Scan the workspace for `spec.md`, `constitution.md`, `plan.md`
- Identify which files are missing
- If any are missing → invoke `setup-project-docs` first
- Once all files are present → invoke validation sub-skills in sequence
- Hand off to `generate-validation-report` at the end

**Trigger phrases:**
- "validate against requirements"
- "cross-check this against the spec"
- "does this meet the requirements"
- "requirements cross-check"
- "check compliance"

**Slash command:** `/requirements-cross-check`

---

### 2. `setup-project-docs` — Template Generator

Runs when any of the three foundational files are missing.

**Responsibilities:**
- Detect which of `spec.md`, `constitution.md`, `plan.md` are absent
- For each missing file:
  - Explain what the file is and why it matters
  - Generate a template with inline comments and guidance so the user knows what to fill in
  - Write the template file to the workspace
  - Ask the user to review and edit it
- Once the user confirms the files are ready, hand back to the orchestrator

**Templates to generate:**

#### `spec.md` template
```markdown
# Feature Specification

## User Story
As a [type of user], I want [goal] so that [benefit].

## Requirements
<!-- List each requirement as a numbered item -->
1. 

## Acceptance Criteria
<!-- Define what "done" looks like for each requirement -->
- [ ] 

## Testing Scenarios
<!-- Describe how each requirement will be tested -->
- 

## Open Questions
<!-- List anything that is still unclear or needs a decision -->
- 
```

#### `constitution.md` template
```markdown
# Project Constitution

## Tech Stack
<!-- List the approved technologies. Bob will flag anything outside this list. -->
- Language: 
- Framework: 
- Database: 
- Other: 

## Coding Standards
<!-- e.g. lint rules, formatting, naming conventions -->
- 

## Testing Standards
<!-- e.g. minimum coverage %, required test types -->
- Unit test coverage: 
- Integration tests required: yes / no

## Security & Compliance Guardrails
<!-- e.g. no hardcoded secrets, auth required on all endpoints -->
- 

## Architecture Decisions (ADRs)
<!-- Link to or summarise key architectural decisions -->
- 
```

#### `plan.md` template
```markdown
# Implementation Plan

## Approach
<!-- High-level summary of how you will implement the feature -->

## Key Design Decisions
<!-- Document significant decisions and why they were made -->
-

## Architectural Diagrams
<!-- Add Mermaid diagrams or descriptions here -->

## Data Models
<!-- Describe any new or modified data structures -->

## Open Questions
<!-- Anything that still needs resolving before implementation -->
-
```

---

### 3. `check-requirements-coverage` — Requirements Validator

Focused entirely on spec coverage.

**Responsibilities:**
- Parse `spec.md` and extract every requirement and acceptance criterion
- Scan the artifact being validated for evidence of each one
- Assign a per-requirement verdict:
  - ✅ **Covered** — clearly and fully addressed
  - ⚠️ **Partial** — mentioned but incomplete or ambiguous
  - ❌ **Missing** — no evidence found in the artifact
- Return structured findings to the orchestrator

---

### 4. `check-constitution-compliance` — Compliance Validator

Focused entirely on constitution guardrails.

**Responsibilities:**
- Parse `constitution.md` and extract all guardrails (tech stack, standards, security rules)
- For each guardrail, check whether the artifact complies
- Assign severity per finding:
  - ❌ **Error** — hard violation, must fix before proceeding
  - ⚠️ **Warning** — deviation from standards, should fix
  - 💡 **Suggestion** — best practice not followed, consider fixing
- Return structured findings to the orchestrator

---

### 5. `generate-validation-report` — Report Assembler

Focused entirely on output formatting.

**Responsibilities:**
- Receive findings from both validation skills
- Assemble a structured report (see Output Format below)
- Calculate coverage score and confidence score
- Write the report to `validation-report.md` in the workspace
- Display the report in chat

---

## Output Format

```
## Requirements Cross-Check Report

### Artifact
[artifact type and name]

### Requirements Coverage (from spec.md)
| # | Requirement | Verdict | Notes |
|---|---|---|---|
| 1 | User can log in with SSO | ✅ Covered | Addressed in section 2.1 |
| 2 | Session timeout after 30 min | ⚠️ Partial | Mentioned but no timeout value specified |
| 3 | Audit log for all auth events | ❌ Missing | No mention found |

Coverage: 1/3 fully met · 1/3 partial · 1/3 missing

---

### Constitution Compliance (from constitution.md)
| Severity | Guardrail | Finding |
|---|---|---|
| ❌ Error | Tech stack: React only | Vue.js referenced — not in approved stack |
| ⚠️ Warning | Unit test coverage ≥ 80% | No test strategy defined |
| 💡 Suggestion | IBM Carbon Design System | No design system reference found |

---

### Fix Priority
1. ❌ [Error] Replace Vue.js with React — violates tech stack constraint
2. ❌ [Missing] Add audit logging to implementation plan
3. ⚠️ [Warning] Add test coverage plan to tasks.md
4. ⚠️ [Partial] Specify session timeout value (30 min) explicitly

---

### Overall
Coverage Score: 33% (1/3 requirements fully met)
Confidence Score: 52/100
Verdict: Significant gaps — 2 requirements unmet, 1 constitution violation must be
resolved before implementation.
```

---

## Full User Journey

```
1. User opens Bob in 🧪 Bob Validation mode
2. User says: "validate against requirements" or /requirements-cross-check
3. Bob (orchestrator) scans workspace for spec.md, constitution.md, plan.md
4. If files missing:
   a. Bob explains what each missing file is
   b. Bob generates templates with inline guidance
   c. Bob writes templates to workspace
   d. Bob asks user to fill them in and confirm
5. Once files are ready, Bob asks: "What artifact do you want to validate?"
6. User provides the artifact (paste, file reference, or current task context)
7. Bob runs requirements coverage check → findings
8. Bob runs constitution compliance check → findings
9. Bob assembles report, writes validation-report.md, displays in chat
10. User reviews fix priority list and acts on it
```

---

## Files to Create

```
.bob/skills/requirements-cross-check/
  SKILL.md                          ← orchestrator skill

.bob/skills/setup-project-docs/
  SKILL.md                          ← template generator skill

.bob/skills/check-requirements-coverage/
  SKILL.md                          ← requirements validator skill

.bob/skills/check-constitution-compliance/
  SKILL.md                          ← compliance validator skill

.bob/skills/generate-validation-report/
  SKILL.md                          ← report assembler skill

docs/
  task4-requirements-cross-check.md ← this file (plan)

bob-chat-history/parshjadon/
  requirements-cross-check.md       ← test session chat history (added after testing)
```

---

## Definition of Done

- [ ] All 5 skills created and activate correctly in Bob Validation mode
- [ ] Orchestrator correctly detects missing files and routes to setup skill
- [ ] Setup skill generates all 3 templates with helpful inline guidance
- [ ] Requirements coverage check produces per-requirement verdicts
- [ ] Constitution compliance check flags violations with correct severity
- [ ] Report assembler writes `validation-report.md` and displays in chat
- [ ] Full user journey tested end-to-end with sample files
- [ ] Chat history saved to `bob-chat-history/parshjadon/`
- [ ] PR opened against `main` with all files
