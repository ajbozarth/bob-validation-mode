# Task 1 — Bob Council (Multi-Agent Review)

## What Is Bob Council?

Bob Council is a three-phase validation pipeline that runs from a single user prompt. The user points at a file or directory; the mode runs every check automatically and delivers a full structured report with no follow-up questions.

The pipeline runs in sequence:

1. **Phase 1 — Deterministic checks** (inline, no subagents) — structural and language quality rules applied to produce a concrete, numbered findings list. Rules either pass or fail; no LLM speculation.
2. **Phase 2 — Confidence Score** — arithmetic score computed directly from Phase 1 findings. The score is a formula, not a judgement.
3. **Phase 3 — Council Debate** — two subagents (The Prosecutor and The Defender) receive the Phase 1 findings as their shared ground truth and argue about *what to do with them*. Neither agent may introduce new findings — the debate is bounded by what Phase 1 actually found.

---

## Why This Design

The previous model spawned five free-roaming reviewer personas. The problem: free-roaming agents reason speculatively — they can invent findings, miss findings, or produce inconsistent results across runs. The debate becomes circular because agents are discovering findings *and* evaluating them at the same time.

The new model separates those two responsibilities:
- **Discovery is deterministic** — Phase 1 runs fixed rules (Markdown structure, DeLLMify patterns, Mermaid syntax). The findings list is reproducible.
- **Evaluation is adversarial** — Phase 3 takes those fixed findings and subjects them to structured argument. The Prosecutor must argue urgency; the Defender must argue proportionality. Both cite the artifact, not speculation.

This makes the Council output trustworthy: the facts are not in dispute, only their priority.

---

## Pipeline Overview

```
User: "validate docs/PLAN.md"
         │
         ▼
Phase 1 — Deterministic Checks (inline)
  ├── markdown-validator skill   → structural findings
  ├── validate_mermaid MCP tool  → diagram syntax findings (if present)
  └── dellmify skill             → language quality findings + density score
         │
         ▼  numbered findings list
Phase 2 — Confidence Score (arithmetic)
  └── formula applied to findings list → score + SHIP/REVIEW/REWORK/DISCARD
         │
         ▼  findings list + score passed as ground truth
Phase 3 — Council Debate (two subagents, parallel)
  ├── ⚖️  The Prosecutor   → argues findings are urgent, ranks priorities
  └── 🛡️  The Defender    → argues findings are lower priority, cases for deferral
         │
         ▼  orchestrator synthesises both
  Council Verdict — per-finding disposition: FIX NOW / FIX SOON / DEFER / CONTESTED
  Final recommendation (may revise Phase 2 score based on debate outcome)
```

---

## Phase 1 — Deterministic Checks

Phase 1 runs inline — no subagents. The orchestrator applies each check in order and compiles all findings into a single numbered table. Each finding is tagged with its source.

### 1a — Markdown Validator (`skills/markdown-validator/SKILL.md`)
Applied when the artifact is a Markdown file. Checks: heading hierarchy, broken link syntax, malformed tables, unclosed code fences, missing image alt text. Source label: `[markdown-validator]`.

### 1b — Mermaid Validator (`validate_mermaid` MCP tool)
Applied when Mermaid fenced blocks are detected. The MCP parser returns hard syntax errors (pass/fail, not LLM reasoning). Source label: `[mermaid-validator]`.

### 1c — DeLLMify Pass (`skills/dellmify/SKILL.md`)
Always applied. Detects LLM-like language patterns (hedges, fillers, deferential phrases). Returns a density score (0–100) and flagged phrases with direct replacements. Source label: `[dellmify]`.

### Findings Table Format

All Phase 1 findings are compiled into one numbered table before Phase 2 begins:

```
| # | Source | Severity | Location | Issue | Fix |
|---|---|---|---|---|---|
| 1 | [markdown-validator] | error | heading at line 4 | skipped from H1 to H3 | change to H2 |
| 2 | [dellmify] | warning | line 12 | "It's worth noting that" | remove — start sentence directly |
```

The finding numbers are the Council's reference system in Phase 3. They must be stable.

---

## Phase 2 — Confidence Score

Arithmetic formula applied to the Phase 1 findings table. No judgment applied here.

| Severity | Deduction per finding |
|---|---|
| `error` | −15 |
| `warning` | −5 |
| `info` | −1 |

DeLLMify density additional deduction: 0–20 → none; 21–50 → −5; 51–80 → −10; 81–100 → −15.

| Score | Recommendation |
|---|---|
| 85–100 | `SHIP` |
| 60–84 | `REVIEW` |
| 30–59 | `REWORK` |
| 0–29 | `DISCARD` |

---

## Phase 3 — Council Debate

Two subagents are spawned in parallel. Both receive the Phase 1 findings list and the Phase 2 score as their only inputs. **Neither agent may introduce findings not in the Phase 1 list.**

### ⚖️ The Prosecutor
Argues that findings are serious and the user should act on them urgently. Ranks the top 3 to fix first. May argue that `info` findings should be elevated to `warning` — must cite the artifact, not assert generically.

### 🛡️ The Defender
Argues that findings are lower priority than they appear. Identifies which findings are safe to defer. May argue `error` findings should be downgraded — must cite specific context from the artifact. Cannot dismiss a finding without explanation.

### Council Verdict Dispositions

| Disposition | Condition |
|---|---|
| `FIX NOW` | Prosecutor argued urgency; Defender did not successfully counter |
| `FIX SOON` | Prosecutor argued urgency; Defender made a valid deferral case |
| `DEFER` | Defender argued low priority; Prosecutor did not contest |
| `CONTESTED` | Both agents argued opposite positions with specific evidence |

A Defender argument is only "successful" if it cites specific content from the artifact. A blanket dismissal is rejected.

The orchestrator may revise the Phase 2 recommendation upward (if most errors are `DEFER`) or downward (if `info` findings were elevated to `FIX NOW`).

---

## Deliverables

### `skills/bob-council/SKILL.md` ✅ implemented

The skill file at `.bob/skills/bob-council/SKILL.md` implements the full pipeline. It must contain:

1. **Frontmatter** — `name`, `description`, `metadata.tags`, `metadata.mcp_servers`
2. **Phase 1 instructions** — how to read the target, apply each check in order, and compile the numbered findings table
3. **Phase 2 instructions** — the arithmetic scoring formula and recommendation thresholds
4. **Phase 3 instructions** — Prosecutor and Defender subagent prompts, Council Verdict synthesis rules, and disposition definitions
5. **Full Report structure** — the exact template rendered to the user
6. **User Interface section** — accepted prompt forms and the single-question fallback

### `.bob/custom_modes.yaml` ✅ updated

The mode's `customInstructions` now encode the pipeline directly so the mode activates it on any file/directory prompt without requiring the skill to be explicitly named.

---

## Implementation Steps

### Step 1 ✅ — Load skill authoring guide
`use_skill("create-skill")` loaded. Frontmatter schema confirmed.

### Step 2 ✅ — Design the pipeline architecture
Replaced five free-roaming personas with the deterministic-first model: Phase 1 (fixed rules) → Phase 2 (arithmetic) → Phase 3 (bounded debate).

### Step 3 ✅ — Write `.bob/skills/bob-council/SKILL.md`
Skill file written with full three-phase pipeline, Prosecutor/Defender prompts, Council Verdict synthesis rules, and single-prompt UX spec.

### Step 4 — Test with a Markdown artifact
Pick a real document from the repo — `docs/IDEAS.md` or `README.md` are good candidates. Run the mode with `validate docs/IDEAS.md` and verify:
- Phase 1 produces a numbered findings table with source labels
- Phase 2 score is computed correctly from the findings count
- Phase 3 spawns both subagents and returns a Council Verdict table with dispositions
- The full report renders without truncation

### Step 5 — Coordinate with Task 7
The mode's `customInstructions` already reference the pipeline. When Task 7 (Mode + Orchestration) runs its end-to-end smoke test, verify that:
- The `bob-council` skill activates when the user says "validate \<path\>"
- The pipeline does not pause for questions when a file path is provided
- The Council Verdict table appears in the final report

---

## Integration Points

| Phase | Integrates with | How |
|---|---|---|
| Phase 1 | **Task 2 — DeLLMify** | DeLLMify skill is called inline in Phase 1d. Density score and findings feed directly into Phase 2 scoring formula. |
| Phase 1 | **Task 5a — Markdown Validator** | Markdown Validator skill is called inline in Phase 1b for `.md` files. |
| Phase 1 | **Task 5b — Mermaid Validator** | `validate_mermaid` MCP tool called inline in Phase 1c when Mermaid blocks detected. |
| Phase 2 | **Task 3 — Confidence Score** | Phase 2 *is* the confidence score — the formula defined here replaces the need for a separate skill invocation within the pipeline. The standalone confidence-score skill remains available for users who want it without the full Council. |
| Phase 3 | **Task 7 — Mode Orchestration** | Mode `customInstructions` encodes the pipeline trigger. The mode activates bob-council on any file/directory validation prompt. |

---

## Acceptance Criteria

The task is complete when all of the following are true:

- [x] `skills/bob-council/SKILL.md` exists and passes the skill frontmatter schema
- [x] Phase 1 instructions cover Markdown Validator, Mermaid Validator (conditional), and DeLLMify (always)
- [x] Phase 1 findings are compiled into a numbered table with source labels before Phase 2 begins
- [x] Phase 2 scoring formula is arithmetic (no judgment) with defined severity weights and recommendation thresholds
- [x] Phase 3 Prosecutor and Defender subagent prompts are written with explicit constraints (no new findings)
- [x] Council Verdict disposition rules (FIX NOW / FIX SOON / DEFER / CONTESTED) are defined with clear conditions
- [x] The mode's `customInstructions` encode the single-prompt pipeline trigger
- [ ] Pipeline has been tested end-to-end against at least one real artifact from this repo
- [ ] Council Verdict table renders correctly in the final report

---

## Open Questions

- **Artifact size limit** — very long files may hit context limits when passed to subagents in Phase 3. Define a threshold (suggested: 8000 tokens) and document what to do (summarise Phase 1 findings only, not the full artifact).
- **Re-run behaviour** — always start fresh. Do not pass prior Council output as context on a second run. Document this explicitly in the skill.
- **Directory with many files** — when validating a directory, Phase 1 processes files sequentially. Define a maximum file count before the pipeline switches to sampling mode (suggested: 10 files; beyond that, ask the user which to prioritise).
