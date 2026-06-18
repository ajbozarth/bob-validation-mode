# Two NAND Gates — Specification

## Overview

A NAND gate is a universal logic gate that outputs LOW (0) only when **all** of its inputs are
HIGH (1). It is the logical complement of an AND gate. Two NAND gates can be combined to
implement useful boolean functions, including a buffer, NOT gate, and SR latch.

---

## 1. Single NAND Gate

### Symbol

```
   A ─┐
       ├──[NAND]──○── Q
   B ─┘
```

### Boolean Expression

```
Q = NOT (A AND B)  =  ¬(A · B)  =  A ↑ B
```

### Truth Table

| A | B | Q = ¬(A·B) |
|---|---|------------|
| 0 | 0 |     1      |
| 0 | 1 |     1      |
| 1 | 0 |     1      |
| 1 | 1 |     0      |

---

## 2. Two NAND Gates in Series (NOT Gate)

Connecting both inputs of the first NAND gate together and feeding its output into both inputs
of the second NAND gate produces a **NOT (inverter)** function.

### Circuit

```
   A ──┬──[NAND₁]──┬──[NAND₂]── Q
       └───────────┘ (both inputs tied)
```

Simplified: tie both inputs of each gate to the same signal.

```
   A ──[NAND₁ (A,A)]──[NAND₂ (X,X)]── Q
```

### Boolean Expression

```
X = ¬(A · A) = ¬A
Q = ¬(X · X) = ¬X = ¬(¬A) = A
```

This configuration acts as a **buffer** (double inversion = identity).

To get a **NOT gate**, use only the first NAND with both inputs tied:

```
Q = ¬(A · A) = ¬A
```

### Truth Table — NOT (single NAND, inputs tied)

| A | Q = ¬A |
|---|--------|
| 0 |   1    |
| 1 |   0    |

### Truth Table — Buffer (two NANDs in series, inputs tied)

| A | X = ¬A | Q = ¬X = A |
|---|--------|------------|
| 0 |   1    |     0      |
| 1 |   0    |     1      |

---

## 3. Two NAND Gates — SR Latch (Cross-Coupled)

Cross-coupling two NAND gates (output of each fed back into the input of the other) produces
an **active-low SR latch** — the fundamental bistable memory element.

### Circuit

```
   S̄ ──┬──[NAND₁]──┬── Q
        │            └──────┐
        │                   │
   R̄ ──┴──[NAND₂]──┴── Q̄
        └────────────────────┘
```

More precisely:

```
NAND₁ inputs: S̄, Q̄   →   Q  = ¬(S̄ · Q̄)
NAND₂ inputs: R̄, Q    →   Q̄  = ¬(R̄ · Q)
```

### Inputs (active-low)

| Signal | Meaning          |
|--------|-----------------|
| S̄ = 0 | Set (assert)    |
| R̄ = 0 | Reset (assert)  |
| S̄ = 1 | Set inactive    |
| R̄ = 1 | Reset inactive  |

### Truth Table — SR Latch (NAND)

| S̄ | R̄ | Q      | Q̄     | State        |
|----|-----|--------|--------|--------------|
| 0  | 0   | 1      | 1      | **Forbidden** (both outputs HIGH — undefined) |
| 0  | 1   | 1      | 0      | **Set**      |
| 1  | 0   | 0      | 1      | **Reset**    |
| 1  | 1   | Q_prev | Q̄_prev | **Hold** (memory) |

### Behaviour Notes

- **Forbidden state** (S̄=0, R̄=0): both outputs driven HIGH simultaneously. When inputs return
  to (1,1), the next state is non-deterministic (race condition). This input combination MUST
  be avoided in practice.
- **Hold state** (S̄=1, R̄=1): the latch retains the previous Q value — this is the memory
  property.
- **Set** (S̄=0, R̄=1): forces Q=1 regardless of previous state.
- **Reset** (S̄=1, R̄=0): forces Q=0 regardless of previous state.

---

## 4. Key Properties

| Property | Value |
|----------|-------|
| Gate type | Universal (can implement any boolean function) |
| CMOS transistors per 2-input NAND | 4 (2 PMOS in parallel, 2 NMOS in series) |
| Propagation delay | Typically faster than NOR in CMOS (PMOS in parallel) |
| Fan-in | 2 inputs (this spec) |
| Fan-out | Technology-dependent; typically ≥ 4 in standard CMOS |

---

## 5. Acceptance Criteria for a Conforming Implementation

| # | Requirement |
|---|-------------|
| AC-1 | A single NAND with both inputs HIGH MUST output LOW. |
| AC-2 | A single NAND with any input LOW MUST output HIGH. |
| AC-3 | Two series NANDs with tied inputs MUST implement a buffer (Q = A). |
| AC-4 | Cross-coupled NAND SR latch MUST hold state when S̄=1, R̄=1. |
| AC-5 | Cross-coupled NAND SR latch MUST set Q=1 when S̄=0, R̄=1. |
| AC-6 | Cross-coupled NAND SR latch MUST reset Q=0 when S̄=1, R̄=0. |
| AC-7 | The forbidden state (S̄=0, R̄=0) MUST be documented and avoided in design. |
