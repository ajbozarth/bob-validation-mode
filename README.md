# bob-validation-mode

A Bob mode that validates outputs before you act on them.

---

## The Problem

LLMs are structurally overconfident. When asked to self-evaluate, models cluster their
confidence scores at 85–95% regardless of actual output quality — a direct artifact of how
they were trained. Errors slip through, hedging language accumulates, requirements go
unverified, and the model has no reliable way to tell you when its output isn't ready.

The result: you act on outputs you shouldn't, and catch problems after the fact instead of
before.

## The Solution

**Bob Validation** is a mode that runs after a task completes to finalise the output before
you act on it. It combines deterministic tooling, a structured confidence score, and a
six-persona council into a single pipeline:

1. **Deterministic checks first.** An MCP server runs Pylint for Python files. A DeLLMify
   pass detects and strips LLM-like hedging and filler language. The findings compile into a
   numbered table that serves as ground truth for the rest of the pipeline.

2. **A confidence score that holds up.** An arithmetic score is computed from the Phase 1
   findings and passed into the council as the baseline. The council then adjusts it based on
   the weight of concerns raised — HIGH concerns deduct 10 points each, MEDIUM deduct 5, LOW
   deduct 2. A Principal Engineer `FUNDAMENTAL ISSUE` verdict or any Security Auditor `error`
   finding caps the score at 40 regardless of other adjustments.

3. **A council of six independent voices.** Six subagents are spawned in parallel, each
   reviewing the artifact from a distinct lens:
   - 🔬 **The Nit-Picker** — precision: inconsistencies, imprecise phrasing, technically wrong claims
   - 🛡️ **The Defender** — proportionality: what is working well and what objections are overblown
   - 🏗️ **The Principal Engineer** — soundness: does the artifact hold up, are tradeoffs acknowledged
   - 🎯 **The Pragmatist** — scope: what can be cut without losing meaning
   - 🔐 **The Security Auditor** — trust: credentials, prompt injection, insecure patterns
   - 👤 **The First-Time Reader** — clarity: where assumed knowledge creates an avoidable barrier

   Concerns raised by two or more personas independently are weighted `HIGH`. The Defender
   can contest findings to reduce their weight. The result is a verdict table with a weighted
   disposition per concern and a final adjusted score.

4. **A requirements cross-check.** A separate pipeline validates any artifact against
   `spec.md` and `constitution.md` — your project's requirements and guardrails — and
   produces a structured coverage and compliance report.

## Why It Matters

Every AI-assisted workflow has the same gap: the model generates, and then you are on your
own to decide if the output is trustworthy. That gap widens as outputs get longer, as
requirements get more specific, and as the cost of acting on a bad output goes up.

A validation layer that runs deterministic checks before any LLM reasoning, computes scores
from evidence rather than self-assessment, and subjects findings to structured adversarial
debate closes that gap in a way that asking the model "are you sure?" never will.

---

## Skills

| Skill | What it does |
|---|---|
| `bob-council` | Runs the full three-phase pipeline: DeLLMify + Pylint → confidence score → six-persona council |
| `dellmify` | Detects and removes LLM-like hedging, filler, and deferential language from any artifact |
| `requirements-cross-check` | Orchestrates the requirements and compliance validation pipeline |
| `check-requirements-coverage` | Checks every requirement in `spec.md` against an artifact; returns per-requirement verdicts |
| `check-constitution-compliance` | Checks every guardrail in `constitution.md` against an artifact; returns severity-rated findings |
| `generate-validation-report` | Assembles coverage and compliance findings into a structured report and writes `validation-report.md` |
| `setup-project-docs` | Creates `spec.md`, `constitution.md`, and `plan.md` templates when they are missing |

## MCP Server

`mcp-pylint` — runs Pylint on Python files and returns structured findings. Called automatically by `bob-council` for `.py` artifacts.

## Mode

Install by adding the entry from [`.bob/custom_modes.yaml`](.bob/custom_modes.yaml) to your workspace's `.bob/custom_modes.yaml`.

### Slug

```text
bob-validation
```

### Trigger phrases

| Phrase | What runs |
|---|---|
| `validate <file>`, `bob council <file>` | Full bob-council pipeline (Phase 1 → 2 → 3) |
| `validate against requirements`, `requirements cross-check` | Requirements and compliance pipeline |
| `DeLLMify <file>` | DeLLMify skill standalone |

### Output

The bob-council pipeline produces:

- A Phase 1 findings table from DeLLMify and Pylint
- A baseline confidence score (0–100) adjusted by the council
- Individual outputs from all six council personas
- A weighted verdict table: `HIGH` / `MEDIUM` / `LOW` / `NOTED` per concern
- A final score and recommendation: `SHIP` / `REVIEW` / `REWORK` / `DISCARD`

The requirements pipeline produces `validation-report.md` with per-requirement coverage verdicts and per-guardrail compliance findings.

## License

[Apache 2.0](LICENSE)
