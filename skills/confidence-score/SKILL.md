---
name: confidence-score
description: >-
  Attach a calibrated confidence score to any generated artifact. Use when the user asks for a
  confidence score, asks how reliable an output is, or asks Bob to assess its own output before
  acting on it. Also invoked by the Bob Council orchestrator to aggregate per-persona rubric scores
  into a final score block. Trigger phrases: "confidence score", "how confident are you",
  "reliability score", "how sure are you", "attach a score", "rate this output".
---

# Confidence Score

Produce a calibrated confidence score for any artifact. This skill is designed to counteract the
structural overconfidence bias in LLM self-evaluation. A naive "how confident are you?" prompt
reliably produces 85–95% — that is the baseline to beat.

**Integration points (non-duplicating):**
- If the **Bob Council** skill has already run, use its per-persona rubric subscores as input to
  Phase 4 instead of running a single-agent rubric. Do not re-run the Council from this skill.
- If the **Requirements Cross-Check** skill has already run, import its coverage verdict
  (covered / partial / missing counts) directly into the Coverage dimension instead of re-evaluating.
- If neither has run, this skill is fully self-contained — execute all phases below independently.

---

## Phase 1 — Identify the Artifact and Spec

Determine what is being scored and what it is being scored *against*:

1. **Artifact** — the generated output to evaluate (Markdown doc, diagram, code, governing doc, etc.)
2. **Spec** — the source requirement, acceptance criteria, prompt, user story, or template the
   artifact was supposed to satisfy.

If no spec is provided, note this explicitly. The absence of a spec does not mean full confidence —
it means the Coverage and Grounding dimensions are capped at 1/2 (partial). State this to the user.

---

## Phase 2 — Isolated Scoring Subagent

The generator-as-judge problem cannot be solved by instruction alone. An agent that produced (or
has already read) an artifact is context-contaminated — its attention is anchored to that content
regardless of what the prompt says. The only reliable fix is genuine epistemic separation: a scorer
that has never seen the generation context.

**Spawn a subagent with `fork_context: false`** and pass it exactly three things:

1. The spec/requirements text
2. The rubric (the five dimensions from Phase 4, copied verbatim)
3. The artifact text

Do NOT pass: conversation history, any reasoning about how the artifact was produced, prior scores,
or any other context. `fork_context: false` is the load-bearing flag — it guarantees a clean
context window with no inherited state.

Instruct the subagent to execute Phases 3 and 4 and return a structured result in this exact format:

```
SCORER RESULT
Grounding:    [0.0–2.0]  [one-line rationale]
Coverage:     [0.0–2.0]  [one-line rationale]
Consistency:  [0.0–2.0]  [one-line rationale]
Specificity:  [0.0–2.0]  [one-line rationale]
Spec Clarity: [0.0–2.0]  [one-line rationale]
Uncertainty Sources:
  • [one bullet per unverified claim or assumption identified in Phase 3]
```

Receive this result. The parent agent resumes at Phase 5 using these scores.

**When Bob Council has already run:** Bob Council's personas are already isolated subagents. Skip
this phase entirely — their per-persona dimension scores are the equivalent output. Proceed
directly to Phase 5.

---

## Phase 3 — Uncertainty Elicitation

Before scoring, explicitly surface what cannot be verified. From the artifact, identify and list:

1. Every claim not derivable from the spec alone (inferences, assumptions, pattern completions)
2. Every requirement in the spec that was ambiguous or underspecified
3. Every section of the artifact where "sounding correct" may have substituted for "being correct"

Each item identified here is a concrete deduction from the base score. A useful heuristic: if you
could not construct a verification test from the spec alone to check the claim, it is unverified.

---

## Phase 4 — Rubric Scoring

Score each dimension independently. **Do not let the holistic impression of the artifact influence
individual dimension scores** — evaluate each dimension in isolation.

If Bob Council scores are available, use the per-persona dimension averages for each field below
instead of scoring yourself. If Requirements Cross-Check output is available, use its coverage
verdict directly for the Coverage dimension.

### Dimensions (each 0–2)

**Grounding** — Does every substantive claim trace to a specific part of the spec or input?
- 2 = All claims grounded; nothing added beyond the spec
- 1 = Mostly grounded; minor inferences present but clearly flagged
- 0 = Unverified claims present without acknowledgment

**Citation Verifiability** *(conditional — apply only if the artifact contains cited sources)*
This sub-dimension folds into Grounding. It is not scored separately; it adjusts the Grounding
score before it is recorded. For each citation in the artifact:
- Verify the link is syntactically valid (not malformed, not a placeholder like `[source]`)
- Verify the link resolves to a real resource (check whether the URL pattern is a known domain
  and path structure; flag DOIs, arXiv IDs, or URLs that appear fabricated or hallucinated)
- Verify the cited source actually supports the claim it is attached to (not just topically related)

Apply these adjustments to the Grounding score:
- Any citation that is a placeholder or syntactically broken: −0.5
- Any citation whose URL pattern suggests hallucination (non-existent arXiv ID, doi that doesn't
  resolve to the described paper, invented journal name): −0.5
- Any citation that does not support the attached claim: −0.25

If no citations are present in the artifact, skip this sub-dimension entirely. Do not penalise
an artifact for lacking citations unless the spec explicitly required them.

Report any citation issues in the Uncertainty Sources list with the specific citation flagged.

**Coverage** — Are all requirements from the spec addressed in the artifact?
- 2 = Complete coverage; every stated requirement is addressed
- 1 = Partial; 1–2 requirements missing or only partially addressed
- 0 = Major gaps; more than 2 requirements missing or addressed incorrectly

**Consistency** — Is the artifact internally consistent? No contradictions between sections?
- 2 = Fully consistent throughout
- 1 = Minor tensions that are resolvable without breaking the spec
- 0 = Contradictions present

**Specificity** — Is the content concrete and actionable, or vague and generic?
- 2 = Specific, concrete, actionable throughout
- 1 = Mixed — some concrete sections, some vague generalities
- 0 = Predominantly vague; could describe almost any artifact of this type

**Spec Clarity** — How clear and complete was the source spec itself?
- 2 = Spec was specific, unambiguous, and testable
- 1 = Spec had some ambiguity; assumptions were required
- 0 = Spec was vague or contradictory (this becomes a hard ceiling — see below)

### Ceiling Rule

If **Spec Clarity = 0**, the maximum possible score is **50**. No artifact can be highly confident
when the spec it was derived from was underspecified — the uncertainty lives in the input, not the
output. Cap the raw score accordingly and state this to the user.

If **Spec Clarity = 1**, the maximum possible score is **80**.

---

## Phase 5 — Variance and Cross-Check

Receive the scorer result from Phase 2 (or Council persona scores if Bob Council ran).

Apply the Phase 3 uncertainty penalty: for each uncertainty source the subagent identified that
directly implicates a grounding-sensitive claim, reduce Grounding by 0.5 (min 0).

If Bob Council was used: compute σ per dimension across all persona scores. Flag any dimension
where σ ≥ 0.7 — high variance means reviewers disagreed and that dimension is unreliable.

If running standalone (single subagent scorer): no variance to compute. Report the subagent's
scores directly.

---

## Phase 6 — Score Calculation and Bucket Assignment

**Calculate the raw score:**
```
raw_score = (sum of dimension scores / 10) × 100
```

**Apply the spec ceiling** (from Phase 4 ceiling rule if triggered).

**Assign a bucket — choose the bucket label first, before the number:**

| Bucket | Range | Meaning |
|--------|-------|---------|
| 🔴 Unreliable | 0–20 | Do not act on this. Major gaps, contradictions, or no verifiable grounding. |
| 🟠 Weak       | 21–40 | Significant issues. Needs substantial revision before use. |
| 🟡 Partial    | 41–60 | Adequate in places but incomplete. Verify key areas before acting. |
| 🟢 Strong     | 61–80 | Good coverage with minor issues. Safe to use with light review. |
| ✅ High       | 81–100 | Complete, grounded, and consistent. Act with confidence. |

The bucket label carries human meaning that a number alone does not. If you would not
personally recommend acting on this artifact, it must be in 🔴 or 🟠 — do not let a
technically-calculated number push it into 🟡 if your judgment says it is weaker.

---

## Phase 7 — Output Block

Emit the score in this exact format. Do not deviate from the structure — consistency across
invocations allows the orchestrating mode to parse and compare scores.

```
---
📊 CONFIDENCE SCORE
---
Score:    [number] / 100  ([bucket emoji] [Bucket Label])

Dimension Breakdown:
  Grounding:     [0.0–2.0]  [brief rationale]
  Coverage:      [0.0–2.0]  [brief rationale]
  Consistency:   [0.0–2.0]  [brief rationale]
  Specificity:   [0.0–2.0]  [brief rationale]
  Spec Clarity:  [0.0–2.0]  [brief rationale]

Uncertainty Sources:
  • [Each item from Phase 3 — one bullet per unverified claim or assumption]
  • (none) if nothing identified

Ceiling Applied: [Yes — Spec Clarity capped score at N | No]

[If Bob Council was used:]
Reviewer Agreement:
  • [Dimension]: σ=[value] — [agreed / minor disagreement / HIGH DISAGREEMENT ⚠️]

Recommendation: [ACT | REVIEW | REVISE | DISCARD]
  [One sentence explaining the recommendation, specifically referencing the weakest dimension
   or the highest-impact uncertainty source.]
---
```

### Recommendation mapping

| Score | Default recommendation |
|-------|----------------------|
| 81–100 | ACT |
| 61–80  | REVIEW |
| 41–60  | REVISE |
| 0–40   | DISCARD |

Override the default if a specific dimension is critically low. A 72 overall with Coverage = 0
should still be REVISE, not REVIEW — missing requirements are a blocker regardless of aggregate score.

---

## Standalone Usage Example

**User:** "Score the confidence of this Epic against the PR-FAQ I provided."

1. Phase 1: Artifact = Epic, Spec = PR-FAQ
2. Phase 2: Spawn scorer subagent (`fork_context: false`) with spec + rubric + artifact only.
            Subagent executes Phases 3–4 and returns the SCORER RESULT block.
3. Phase 5: Receive scores. Apply uncertainty penalties to Grounding if warranted.
            No variance to compute (single scorer).
4. Phase 6: Calculate score, apply ceiling if Spec Clarity triggered it, pick bucket label first.
5. Phase 7: Emit output block.

---

## Bob Council Integration Example

**Bob Council has already run and returned per-persona rubric scores.**

Skip Phase 2 (Council personas are already isolated subagents — the separation is already done).
Jump directly to Phase 5:
- Import per-persona dimension scores from the Council synthesis report
- Compute σ per dimension across the individual reviewer scores
- Flag high-variance dimensions (σ ≥ 0.7)
- Proceed to Phase 6 and 7

The Council's "Requirements Reviewer" persona will typically have the most informative Coverage
score — weight it accordingly if the other personas scored outside their primary expertise.

---

## Requirements Cross-Check Integration Example

**Requirements Cross-Check has already run and returned a coverage matrix.**

For the Coverage dimension in Phase 4:
- Count the requirements marked `missing` (weight: −1 each, min 0)
- Count the requirements marked `partial` (weight: −0.5 each)
- Map to 0/1/2: 0 missing + 0 partial = 2; any partial but no missing = 1; any missing = 0

Do not re-evaluate coverage yourself — import the cross-check result directly.
