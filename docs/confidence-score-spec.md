# Confidence Score Skill — Requirements Specification

## Problem Statement

LLMs exhibit systematic overconfidence when asked to self-evaluate. Verbalized confidence scores
produced by a naive "how confident are you?" prompt cluster at 85–95% regardless of actual output
quality. This is a structural artifact of RLHF and instruction-tuning, not a reasoning failure —
the model generates a token that *sounds confident* because confident-sounding tokens were
reinforced during training. The overconfidence is present across all model sizes and persists even
in 70B+ models with an average Expected Calibration Error of ~0.1 (Yang et al., 2024).

The goal of this skill is not to produce a number. It is to produce a number that **correlates with
human judgment**: when a human operator would rate an artifact as insufficient, the skill must
output a score below 60. When a human would rate it as reliable, the skill must output above 70.
The 95%-always baseline is the failure mode to eliminate.

## Acceptance Criteria

A conforming implementation of this skill MUST satisfy all of the following:

### AC-1 — Context Separation
The agent that scores the artifact MUST NOT be the same agent instance that generated or
extensively reviewed it in the same context window. Scoring in the same context as generation is
the primary source of overconfidence inflation and MUST be architecturally prevented, not
instructed around. Acceptable implementations: subagent with `fork_context: false`, or a
separately-invoked agent session.

### AC-2 — Structured Rubric, No Open-Ended Self-Assessment
The skill MUST derive the confidence score from a set of specific, independently-evaluated
dimensions rather than from a single holistic self-assessment question. Each dimension MUST be
scoreable on its own without reference to the overall impression of the artifact. Rationale:
models are better calibrated on specific factual questions than on abstract self-assessments
(Kadavath et al., 2022; Xiong et al., 2024).

### AC-3 — Uncertainty Elicitation Before Scoring
The scoring agent MUST explicitly list unverified claims, assumptions, and spec ambiguities
*before* assigning dimension scores. Each identified uncertainty MUST mechanically reduce at
least one dimension score. The elicitation step MUST NOT be skippable or optional.

### AC-4 — Spec-Driven Coverage Ceiling
If the source specification is itself ambiguous or underspecified, the maximum achievable
confidence score MUST be capped below 100. An artifact cannot be fully reliable when the
requirement it addresses was unclear. The ceiling MUST be derived from a scored assessment of
the spec's clarity, not from the artifact.

### AC-5 — Sub-50 Scores Are Reachable
The skill MUST be capable of producing scores below 50 in realistic conditions. A
conforming implementation MUST NOT have any structural bias (prompt framing, scale anchoring,
or default assumptions) that makes scores below 50 unlikely. Test: given an artifact that
demonstrably misses more than two requirements from a clear spec, the skill MUST output a
score ≤ 40.

### AC-6 — Bucket-First Assignment
The skill MUST require the scoring agent to assign a human-readable severity bucket
(e.g. Unreliable / Weak / Partial / Strong / High) *before* committing to a numeric value
within that bucket. The bucket assignment forces commitment to a categorical judgment before
precision-anchoring, reducing the tendency to default to high numbers. Rationale: coarse
categorical judgments are better calibrated than fine-grained continuous estimates in LLMs
(verbalized confidence literature, 2024–2025).

### AC-7 — Structured Output Block
Every invocation MUST produce a machine-parseable output block containing: numeric score,
bucket label, per-dimension scores with one-line rationales, uncertainty sources list,
ceiling-applied flag, and a recommendation from the set {ACT, REVIEW, REVISE, DISCARD}.
The format MUST be consistent across invocations to allow downstream parsing by an
orchestrating mode or Council aggregator.

### AC-8 — Recommendation Override for Critical Dimension Failures
The default recommendation mapping (score range → recommendation) MUST be overridable when
any single dimension scores 0/2. A zero on Coverage or Grounding is a blocker regardless
of aggregate score and MUST produce at minimum a REVISE recommendation. The skill MUST NOT
allow a high aggregate to mask a zero in a critical dimension.

### AC-9 — Bob Council Integration Without Duplication
When Bob Council has already produced per-persona rubric scores, the skill MUST import those
scores and MUST NOT re-spawn scorer agents or re-evaluate dimensions independently. The
Council personas are already isolated scorers — duplicating the isolation is waste. The
skill owns aggregation, ceiling application, bucket assignment, and output formatting.

### AC-10 — Requirements Cross-Check Integration Without Duplication
When the Requirements Cross-Check skill has already produced a coverage matrix, the skill
MUST derive the Coverage dimension score directly from that matrix (missing requirements → 0,
partial → 1, full → 2) rather than re-evaluating coverage independently.

## Non-Goals

- This skill does NOT improve the quality of the artifact being scored. It only estimates
  confidence in that artifact.
- This skill does NOT re-run or duplicate Bob Council or Requirements Cross-Check.
- This skill does NOT produce fine-grained probability estimates at the token or sentence
  level. It operates at the artifact level.
- This skill does NOT require model fine-tuning or access to logit probabilities. It is a
  pure prompt-engineering and agentic-architecture solution.

## Key Research Basis

| Technique | Source | Mapped to |
|-----------|--------|-----------|
| Self-consistency sampling as calibration signal | [Xiong et al., 2024][xiong]; [ADVICE, arXiv 2510.10913][advice] | AC-1, AC-2: isolated subagent produces independent scores |
| Structured rubric over holistic self-assessment | [Kadavath et al., 2022][kadavath]; ACL TrustNLP 2025 | AC-2 |
| Explicit uncertainty elicitation | [Jung et al., 2022][jung]; [Nafar et al., 2025][nafar] | AC-3 |
| Spec clarity as confidence ceiling | Inferred from calibration literature | AC-4 |
| Calibrated confidence via multi-agent debate with independent scoring | [ConfidenceCal, Bai et al., 2024][confidencecal] | AC-1, AC-9 |
| Coarse categorical > fine-grained continuous for LLM calibration | [Yang et al., arXiv 2412.14737][yang] | AC-6 |
| RLHF-induced overconfidence is persistent; post-hoc correction required | [Emergent Mind survey, Jan 2026][emergentmind] | AC-1, AC-5 |

## Testable Scenarios

A conforming skill MUST produce scores in the ranges below when applied to the described inputs:

| Scenario | Expected score range |
|----------|---------------------|
| Artifact fully covers a clear spec, no unverified claims | 80–100 |
| Artifact covers spec but spec was ambiguous (requires assumptions) | 50–75 |
| Artifact misses 1–2 requirements from a clear spec | 40–65 |
| Artifact misses 3+ requirements or contains contradictions | ≤ 40 |
| Spec was vague; artifact produced by pattern-completion | ≤ 50 (ceiling rule) |
| No spec provided | ≤ 60 (Coverage and Grounding capped at 1/2) |

---

## Works Cited

[kadavath]: https://www.anthropic.com/research/language-models-mostly-know-what-they-know
  Kadavath, S. et al. (2022). *Language Models (Mostly) Know What They Know*. Anthropic.

[xiong]: https://arxiv.org/abs/2306.13063
  Xiong, M. et al. (2024). *Can LLMs Express Their Uncertainty? An Empirical Evaluation of Confidence Elicitation in LLMs*. arXiv:2306.13063.

[yang]: https://arxiv.org/abs/2412.14737
  Yang, D. et al. (2024). *On Verbalized Confidence Scores for LLMs*. arXiv:2412.14737.

[advice]: https://arxiv.org/abs/2510.10913
  Levi, D. et al. (2025). *ADVICE: Answer-Dependent Verbalized Confidence Estimation*. arXiv:2510.10913.

[confidencecal]: https://www.semanticscholar.org/paper/ConfidenceCal%3A-Enhancing-LLMs-Reliability-through-Bai/9c46c33b3ae9ddd7d98dffa73d6d4240392bf4bd
  Bai, Y. et al. (2024). *ConfidenceCal: Enhancing LLMs Reliability through Confidence Calibration in Multi-Agent Debate*. Semantic Scholar.

[jung]: https://aclanthology.org/2022.emnlp-main.82
  Jung, J. et al. (2022). *Maieutic Prompting: Logically Consistent Reasoning with Recursive Explanations*. EMNLP 2022.

[nafar]: https://arxiv.org/abs/2505.15918
  Nafar, M. et al. (2025). *Extracting Probabilistic Knowledge from Large Language Models for Bayesian Network Parameterization*. arXiv:2505.15918.

[emergentmind]: https://www.emergentmind.com/topics/confidence-calibration-in-llms
  Emergent Mind. (2026, January 24). *Confidence Calibration in LLMs*. Emergent Mind Topics.
