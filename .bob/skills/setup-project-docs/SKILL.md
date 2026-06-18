---
name: setup-project-docs
description: Use when spec.md, constitution.md, or plan.md are missing from the workspace and need to be created before validation can begin. Generates templates with inline guidance for each missing file and asks the user to fill them in.
---

# Setup Project Docs — Template Generator

You are invoked by the requirements-cross-check orchestrator when foundational files are missing.
Your job is to create clear, well-guided templates so the user can fill in their project details
before validation begins.

## Step 1 — Confirm which files are missing

You will have been told which files are missing. State them clearly to the user:

"Before we can run the validation, I need to create the following files — they are the
foundation the checks run against:

- `spec.md` — your feature requirements and acceptance criteria
- `constitution.md` — your project's tech stack, standards, and compliance guardrails
- `plan.md` — your implementation approach and design decisions

I'll create a template for each missing file with guidance on what to fill in."

Only mention files that are actually missing.

## Step 2 — Create spec.md (if missing)

Write the following template to `spec.md` in the workspace root using `write_file`:

```markdown
# Feature Specification

<!-- What feature or change is this spec for? Replace this comment with a title. -->

## User Story
<!-- Describe who needs this and why. Format: "As a [user type], I want [goal] so that [benefit]." -->
As a [type of user], I want [goal] so that [benefit].

## Requirements
<!-- List each requirement as a numbered item. Be specific — vague requirements are hard to validate. -->
1. 
2. 
3. 

## Acceptance Criteria
<!-- Define exactly what "done" looks like. Each item should be testable (pass/fail). -->
- [ ] 
- [ ] 
- [ ] 

## Testing Scenarios
<!-- Describe the scenarios that will be used to test each requirement. -->
- Scenario 1: 
- Scenario 2: 

## Open Questions
<!-- List anything still unclear or needing a decision before implementation starts. -->
- 
```

After writing the file, tell the user:
"I've created `spec.md`. Fill in your feature requirements and acceptance criteria — the more
specific you are, the better the validation will be."

## Step 3 — Create constitution.md (if missing)

Write the following template to `constitution.md` in the workspace root using `write_file`:

```markdown
# Project Constitution

<!-- This file defines the golden paths for your project.
     Bob will check every artifact against these guardrails during validation. -->

## Tech Stack
<!-- List every approved technology. Bob will flag anything used outside this list. -->
- Language: 
- Framework: 
- Database: 
- Testing framework: 
- Other approved tools: 

## Coding Standards
<!-- e.g. ESLint config, naming conventions, file structure rules, formatting rules -->
- 
- 

## Testing Standards
<!-- Define the minimum bar for testing. Be specific about percentages and test types. -->
- Unit test coverage minimum: %
- Integration tests required: yes / no
- E2E tests required: yes / no

## Security & Compliance Guardrails
<!-- List hard rules around security. e.g. "No hardcoded secrets", "Auth required on all endpoints" -->
- 
- 

## Architecture Decisions (ADRs)
<!-- Summarise or link to key architectural decisions that must be respected. -->
- 
```

After writing the file, tell the user:
"I've created `constitution.md`. Fill in your tech stack and project guardrails — this is what
Bob will check every artifact against for compliance."

## Step 4 — Create plan.md (if missing)

Write the following template to `plan.md` in the workspace root using `write_file`:

```markdown
# Implementation Plan

<!-- High-level plan for how the feature will be built. -->

## Approach
<!-- Summarise the implementation strategy in 2-4 sentences. -->

## Key Design Decisions
<!-- Document significant decisions and the reasoning behind them. -->
- Decision 1: 
- Decision 2: 

## Architectural Diagrams
<!-- Add Mermaid diagrams here if relevant. Example:
```mermaid
graph TD
  A[User] --> B[API]
  B --> C[Database]
```
-->

## Data Models
<!-- Describe any new or modified data structures, schemas, or models. -->

## Phases
<!-- Break the implementation into phases or milestones. -->
- Phase 1: 
- Phase 2: 

## Open Questions
<!-- Anything still unresolved that could affect implementation. -->
- 
```

After writing the file, tell the user:
"I've created `plan.md`. Fill in your implementation approach and key design decisions."

## Step 5 — Hand back to the user

Once all missing templates have been created, tell the user:

"All template files are ready. Here's what to do next:

1. Open each file and fill in your project details
2. The inline comments (<!-- ... -->) will guide you on what each section needs
3. When you're done, come back and say **'ready to validate'** and I'll run the full
   requirements cross-check

Take as much time as you need — the more detail you add, the more thorough the validation."
