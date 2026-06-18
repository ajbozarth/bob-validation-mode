---
name: check-constitution-compliance
description: Use when validating whether an artifact complies with the project's constitution — checks tech stack, coding standards, testing standards, security guardrails, and architecture decisions defined in constitution.md. Returns severity-rated findings.
---

# Check Constitution Compliance — Compliance Validator

You are invoked by the requirements-cross-check orchestrator. Your job is one thing only:
systematically check every guardrail in `constitution.md` against the provided artifact and
return severity-rated findings. Do not generate a final report — that is the job of the
generate-validation-report skill.

## Step 1 — Read constitution.md

Use `read_file` to read `constitution.md` in full.

Extract guardrails from each section and group them by category:
- **Tech Stack** — approved languages, frameworks, databases, tools
- **Coding Standards** — naming conventions, formatting, lint rules
- **Testing Standards** — coverage minimums, required test types
- **Security & Compliance** — hard rules around secrets, auth, data handling
- **Architecture Decisions (ADRs)** — decisions that must be respected

If `constitution.md` is empty or only contains template placeholder text, stop and tell
the user:
"Your `constitution.md` appears to be empty or still contains only the template placeholders.
Please fill it in with your project guardrails before running the compliance check."

## Step 2 — Read the artifact

If the artifact was provided as a file path, use `read_file` to load it.
If the artifact was pasted as text, use it directly.

## Step 3 — Check each guardrail

For every guardrail extracted in Step 1, scan the artifact and assign a severity:

- ❌ **Error** — the artifact explicitly violates this guardrail, or there is a hard
  conflict. This must be fixed before the artifact can move to the next pipeline stage.
  Examples: wrong tech stack used, hardcoded secrets present, unapproved library imported.

- ⚠️ **Warning** — the artifact does not follow this standard but it is not a hard
  violation. Should be fixed but not a blocker.
  Examples: no test strategy defined, naming convention not followed, no coverage target stated.

- 💡 **Suggestion** — a best practice from the constitution is not reflected in the
  artifact. Consider fixing but low urgency.
  Examples: recommended design system not referenced, ADR not cited in a design decision.

- ✅ **Compliant** — the artifact clearly follows this guardrail.

Be precise about where in the artifact the violation or compliance evidence was found.

## Step 4 — Return structured findings

Return your findings in this exact format so the orchestrator and report skill can use them:

```
CONSTITUTION COMPLIANCE FINDINGS

Artifact: [name or type]
Source: constitution.md

TECH STACK
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ✅ Compliant | Language: TypeScript | TypeScript used throughout | All source files |
| ❌ Error | Framework: React only | Vue.js component referenced | Section 3.2 |

CODING STANDARDS
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ⚠️ Warning | camelCase naming | snake_case used for variable names | Code block, line 12 |

TESTING STANDARDS
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ⚠️ Warning | Unit test coverage ≥ 80% | No test strategy defined | Not mentioned |

SECURITY & COMPLIANCE
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| ✅ Compliant | No hardcoded secrets | No secrets found | All sections reviewed |

ARCHITECTURE DECISIONS
| Severity | Guardrail | Finding | Location in Artifact |
|---|---|---|---|
| 💡 Suggestion | ADR-001: REST over GraphQL | No API style mentioned | API design section |

SUMMARY
- Total guardrails checked: X
- Compliant: X
- Errors: X
- Warnings: X
- Suggestions: X
```

Do not add commentary or a fix list — that is assembled by the report skill.
Return only the structured findings above.
