# confidence-score

Attach a calibrated confidence score to any generated artifact before acting on it.

## What it does

Counteracts the structural overconfidence bias in LLM self-evaluation. A naive "how confident are you?" prompt reliably produces 85–95% — this skill is designed to beat that baseline.

The skill scores artifacts across five rubric dimensions, applies deterministic uncertainty penalties, enforces spec-quality ceilings, and emits a structured output block with a bucket label and actionable recommendation.

## When to use it

Trigger this skill when you:

- Want a confidence score attached to any generated output (doc, code, diagram, governing document)
- Ask "how confident are you?" or "how reliable is this?"
- Want Bob to self-assess before you act on an output
- Are running a **Bob Council** multi-agent review and need scores aggregated into a final block

**Trigger phrases:** "confidence score", "how confident are you", "reliability score", "how sure are you", "attach a score", "rate this output"

## How it works

The skill runs in seven phases:

| Phase | What happens |
|-------|-------------|
| 1 — Identify | Establish the artifact and the spec it is being scored against |
| 2 — Isolated scorer | Spawn a `fork_context: false` subagent to score without generation context |
| 3 — Uncertainty elicitation | Subagent surfaces every unverifiable claim, assumption, and spec gap |
| 4 — Rubric scoring | Score five dimensions (Grounding, Coverage, Consistency, Specificity, Spec Clarity), each 0–2 |
| 5 — Variance & penalties | Apply −0.5 per uncertainty item to its mapped dimension (floor 0) |
| 6 — Calculation | `(sum / 10) × 100`, apply the lowest active ceiling, assign a bucket label |
| 7 — Output block | Emit a structured `📊 CONFIDENCE SCORE` block |

## Output

```
---
📊 CONFIDENCE SCORE
---
Score:    72 / 100  (🟢 Strong)

Dimension Breakdown:
  Grounding:     1.5  All claims trace to spec; one design decision flagged
  Coverage:      2.0  All requirements addressed
  Consistency:   2.0  No contradictions
  Specificity:   1.0  Mixed — some vague sections in section 3
  Spec Clarity:  1.5  Minor ambiguity in AC-4

Uncertainty Sources:
  • Inferred rollout timeline not specified in spec

Ceiling Applied: No

Recommendation: REVIEW
  Specificity is the weakest dimension — verify section 3 before acting.
---
```

## Integrations

- **Bob Council** — if Council has already run, its per-persona dimension scores replace Phase 2–4. Variance (σ) across reviewers is computed per dimension; σ ≥ 0.7 is flagged.
- **Requirements Cross-Check** — if a coverage matrix exists, its `covered / partial / missing` counts are imported directly into the Coverage dimension. Neither integration re-runs work already done.

## Ceilings

| Condition | Max score |
|-----------|-----------|
| No spec provided | 60 |
| Spec Clarity = 1 (ambiguous spec) | 80 |
| Spec Clarity = 0 (vague/contradictory spec) | 50 |

When multiple ceilings apply, the lowest wins.
