# Bob Validation Mode — Demo Video Script

Introduction and directory walkthrough · Functionality demo scripted separately by presenter

> **How to read this script**
> **SPEAK** — words to say on camera | **ACTION** — what to show/do on screen | **NOTE** — presenter reminder, not spoken

---

## Part 1 — Introduction (~90 sec)

**SPEAK**

Hi — I'm going to walk you through Bob Validation Mode, a custom mode for the Bob AI assistant that adds a structured self-review layer on top of Bob's normal outputs.

**SPEAK**

The core problem it solves is this: LLMs are structurally overconfident. If you ask Bob "how sure are you about that?" cold, it will tell you 90%. Every time. Regardless of whether the output is actually good.

Bob Validation Mode breaks that pattern by routing every artifact through a deterministic sequence of focused checks — and by using isolated subagents to score outputs without inheriting the generation context that produced them.

**SPEAK**

The mode supports eight types of checks, and it knows which ones to run automatically based on what you hand it:

- Markdown structure validation
- Mermaid diagram syntax and semantic coherence
- Python linting via a dedicated MCP tool
- Requirements coverage against a spec
- Constitution compliance against your project guardrails
- DeLLMify — stripping hedging and LLM-like filler from prose
- A calibrated confidence score with a five-dimension breakdown
- And finally, the Bob Council — six independent reviewer personas running in parallel, each examining the artifact from a different angle, synthesising into a single weighted verdict

**NOTE:** Pause naturally after listing the eight checks. Let the list land before moving on.

**SPEAK**

None of these are ad hoc — every check is a SKILL.md file with exact methodology, output format, and integration rules. The mode is fully inspectable, fully editable, and designed to be extended.

---

## Part 2 — Directory Structure Walkthrough (~2 min)

**ACTION:** Open the file explorer and expand the `.bob/` folder so the full tree is visible.

**SPEAK**

Everything lives under the `.bob` directory. There are two configuration files and one skills folder. Let's go through them.

```
.bob/
├── custom_modes.yaml    ← the mode definition
├── mcp.json             ← MCP server registrations
└── skills/
    ├── bob-council/
    ├── check-constitution-compliance/
    ├── check-requirements-coverage/
    ├── confidence-score/
    ├── dellmify/
    ├── generate-validation-report/
    ├── markdown-validator/
    ├── mermaid-validator/
    ├── requirements-cross-check/
    ├── setup-project-docs/
    └── skill-writing/
```

**ACTION:** Open `custom_modes.yaml`.

**SPEAK**

`custom_modes.yaml` is where the mode is defined. It has four parts.

The slug and name register it with Bob — that's what makes "Bob Validation" appear as a selectable mode.

The `roleDefinition` is the system prompt Bob runs under in this mode. It tells Bob what each artifact type is and which skill handles it.

The `whenToUse` block and its trigger phrases are what Bob reads to decide whether to switch into this mode automatically — things like "validate", "confidence score", "DeLLMify", "Bob Council".

And `customInstructions` is the routing logic — the rulebook Bob follows when it receives a validation request. It defines the full eight-step sequence for a complete validation, the single-skill shortcut path, and the special cases like the pylint MCP tool and the confidence-score escalation offer.

**ACTION:** Scroll to the Routing Logic section inside `customInstructions` — roughly line 97 onwards — so the numbered sequence a–h is visible.

**SPEAK**

This is the full validation sequence. Eight steps, run in order. The first four are conditional on what the artifact contains — pylint only runs for Python files, markdown-validator only runs if there's Markdown, and so on. Steps e through h are unconditional — dellmify, confidence-score, then the Bob Council, then a final confidence-score re-run using the Council's adjusted score as the authoritative output.

**ACTION:** Close `custom_modes.yaml`. Open `mcp.json`.

**SPEAK**

`mcp.json` registers the MCP servers the mode depends on. The bob-validation server exposes two tools: `validate_mermaid`, which is the deterministic Mermaid parser, and `pylint_check`, which runs pylint on Python files and auto-installs it if it's not present. These are the two cases where we need a real tool call rather than just model reasoning.

**ACTION:** Close `mcp.json`. Expand the `skills/` folder in the explorer.

**SPEAK**

Each skill is a directory with a `SKILL.md` file inside. That file is the complete specification for the skill — it tells Bob exactly what to do, step by step, including the exact output format it must produce. Bob loads this file into context when the skill is invoked.

There are ten skills here. Four are standalone validators — `markdown-validator`, `mermaid-validator`, `dellmify`, and `confidence-score`. These can be invoked on their own or as part of the full sequence.

Three are the requirements pipeline — `check-requirements-coverage`, `check-constitution-compliance`, and `generate-validation-report`. These are never called directly. They're always orchestrated through `requirements-cross-check`, which acts as the entry point.

`setup-project-docs` is a helper — it generates `spec.md`, `constitution.md`, and `plan.md` templates when they're missing, so the requirements pipeline has something to run against.

And `bob-council` is the multi-agent reviewer. It spawns six personas in parallel — a Nit-Picker, a Defender, a Principal Engineer, a Pragmatist, a Security Auditor, and a First-Time Reader — collects their findings, and synthesises them into a single weighted Council Verdict with a final score.

And finally, `skill-writing` is the meta-skill — it's the guide for creating new skills for Bob, with the correct directory structure, frontmatter schema, and tool vocabulary.

**ACTION:** Open `skills/bob-council/SKILL.md` and scroll briefly through the six persona definitions to show they are fully specified.

**SPEAK**

Each persona definition is a full instruction block — exactly what gets passed to that subagent. The Nit-Picker hunts word-choice inconsistencies and imprecise claims. The Defender argues what's working and pushes back on disproportionate criticism. The Principal Engineer asks whether the artifact actually holds up architecturally. The Pragmatist asks what can be cut. The Security Auditor looks for trust boundary violations and sensitive data. And the First-Time Reader checks whether someone cold could understand and act on it.

They run in parallel. None of them see each other's outputs. The orchestrator synthesises after all six return.

**NOTE:** This is the natural handoff point to the live functionality demo. Close the SKILL.md and switch to the Bob chat interface.

**SPEAK**

That's the full structure. Let me now show you what it looks like when it actually runs.

---

*Total scripted runtime: ~3.5 minutes · Functionality demo: presenter-led, not scripted here*
