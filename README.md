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

Two tools, both called automatically by the skills — you never invoke them directly:

| Tool | What it does |
|---|---|
| `validate_mermaid` | Runs the Mermaid parser on a diagram string and returns syntax errors |
| `pylint_check` | Runs Pylint on a Python file and returns structured findings |

## Installation

### Prerequisites

- [Bob](https://github.com/ibm/bob) installed
- Node.js 18+

### Steps

```bash
git clone https://github.com/ajbozarth/bob-validation-mode.git
cd bob-validation-mode
./scripts/install.sh
```

Then restart Bob (start a new session). The mode, skills, and MCP server are live.

### What the installer does

| Step | Action |
|---|---|
| 1 | Builds the MCP server (`npm ci && npm run build` inside `mcp-server/`) |
| 2 | Copies each skill directory into `~/.bob/skills/` |
| 3 | Appends the mode entry to `~/.bob/settings/custom_modes.yaml` |
| 4 | Adds the MCP server entry to `~/.bob/settings/mcp.json` |

Re-running `./scripts/install.sh` after a `git pull` rebuilds the MCP server and re-copies the skills.

### Uninstall

```bash
./scripts/uninstall.sh
```

Removes copied skills, the mode entry, and the MCP registration. The cloned repo is left in place.

## Mode

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

## Prompt Documentation

Real Bob chat transcripts showing the prompts used and outputs produced during development are in [`bob-chat-history/`](bob-chat-history/), organised by team member.

## Planning Docs

Design and planning documents covering the architecture, skill specs, and task breakdown are in [`docs/`](docs/).

## License

[Apache 2.0](LICENSE)
