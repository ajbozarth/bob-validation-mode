# bob-validation-mode

A Bob mode that validates Bob's own outputs before presenting them to the user.

## Overview

**Bob Validation** is a mode (with planned skills and tool integrations) that adds a self-review layer to Bob's workflow. Instead of generating an output and immediately presenting it, Bob in Validation Mode examines the output for errors, uncertainty, and quality issues — then reports findings before the user acts on them.

## Mode

The mode definition lives in [`mode.yaml`](mode.yaml). Install it by appending the entry under `customModes` in your `~/.bob/settings/custom_modes.yaml` (global) or `.bob/custom_modes.yaml` (workspace).

### Slug

```
bob-validation
```

### What it validates

| Artifact | Checks |
|---|---|
| Markdown | Structure, links, tables, code blocks, IBM style |
| Diagrams (Mermaid) | Syntax validity, layout coherence, accuracy |
| Code | Syntax, logic errors, security anti-patterns (static only) |
| Governing documents | Template completeness, internal consistency, requirements alignment |
| Any output | DeLLMify pass, confidence score, requirements cross-check |

### Output format

Findings are reported as a structured list:

- **Severity** — `error` / `warning` / `suggestion`
- **Location** — specific element or line reference
- **Description** — what the issue is
- **Recommended fix** — what a correct version looks like

Followed by an overall **confidence score** (0–100) and a one-line **verdict**.

## Planned features

See [`docs/IDEAS.md`](docs/IDEAS.md) for the full backlog of ideas, including Bob Council (multi-agent critique), Mellea integration, and more.

## License

[Apache 2.0](LICENSE)
