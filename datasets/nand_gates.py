"""NAND gate logic implementations derived from docs/nand-gates-spec.md.

Covers:
- Single 2-input NAND gate (Section 1)
- NOT gate via single NAND with tied inputs (Section 2)
- Buffer via two NANDs in series with tied inputs (Section 2)
- SR latch via two cross-coupled NANDs (Section 3)
"""


# ---------------------------------------------------------------------------
# Section 1 — Single NAND Gate
# Q = NOT (A AND B)
# ---------------------------------------------------------------------------

def nand(a: int, b: int) -> int:
    """Return NAND of two single-bit inputs (0 or 1).

    Truth table:
        A=0, B=0 -> 1
        A=0, B=1 -> 1
        A=1, B=0 -> 1
        A=1, B=1 -> 0
    """
    return int(not (a and b))


# ---------------------------------------------------------------------------
# Section 2 — NOT gate (single NAND, both inputs tied)
# Q = NOT A  =  nand(A, A)
# ---------------------------------------------------------------------------

def not_gate(a: int) -> int:
    """Return logical NOT of a using a single NAND with tied inputs.

    Q = ¬(A · A) = ¬A
    """
    return nand(a, a)


# ---------------------------------------------------------------------------
# Section 2 — Buffer (two NANDs in series, both inputs tied each time)
# X = nand(A, A) = NOT A
# Q = nand(X, X) = NOT X = A
# ---------------------------------------------------------------------------

def buffer_gate(a: int) -> int:
    """Return A unchanged using two series NANDs with tied inputs (double inversion).

    X = ¬A,  Q = ¬X = A
    """
    x = nand(a, a)
    return nand(x, x)


# ---------------------------------------------------------------------------
# Section 3 — SR Latch (two cross-coupled NANDs)
# Active-low inputs: S_bar, R_bar
# NAND₁: Q  = ¬(S̄ · Q̄)
# NAND₂: Q̄  = ¬(R̄ · Q)
# ---------------------------------------------------------------------------

class SRLatch:
    """Active-low SR latch built from two cross-coupled NAND gates.

    Inputs are active-low:
        s_bar=0, r_bar=1  -> Set   (Q=1)
        s_bar=1, r_bar=0  -> Reset (Q=0)
        s_bar=1, r_bar=1  -> Hold  (Q unchanged)
        s_bar=0, r_bar=0  -> Forbidden (raises ValueError per AC-7)
    """

    def __init__(self) -> None:
        # Power-on state: both inputs inactive (1,1) -> hold; start reset (Q=0)
        self._q: int = 0
        self._q_bar: int = 1

    @property
    def q(self) -> int:
        """Current Q output."""
        return self._q

    @property
    def q_bar(self) -> int:
        """Current Q̄ output."""
        return self._q_bar

    def apply(self, s_bar: int, r_bar: int) -> tuple[int, int]:
        """Apply active-low S̄/R̄ inputs and return (Q, Q̄).

        Args:
            s_bar: Active-low Set input (0 = assert Set).
            r_bar: Active-low Reset input (0 = assert Reset).

        Returns:
            Tuple (Q, Q̄) after the input is applied.

        Raises:
            ValueError: If the forbidden state s_bar=0, r_bar=0 is applied (AC-7).
        """
        # AC-7: forbidden state must be rejected
        if s_bar == 0 and r_bar == 0:
            raise ValueError(
                "Forbidden state: s_bar=0, r_bar=0 produces non-deterministic output "
                "and MUST be avoided (see spec AC-7)."
            )

        # Iterate the cross-coupled equations until stable (one pass is enough
        # for the three legal states, but two passes ensures convergence).
        for _ in range(2):
            new_q = nand(s_bar, self._q_bar)      # NAND₁: Q  = ¬(S̄ · Q̄)
            new_q_bar = nand(r_bar, new_q)         # NAND₂: Q̄  = ¬(R̄ · Q)
            self._q, self._q_bar = new_q, new_q_bar

        return self._q, self._q_bar


# ---------------------------------------------------------------------------
# __main__ — demonstration of all three configurations
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=== Single NAND gate (Section 1) ===")
    for a in (0, 1):
        for b in (0, 1):
            print(f"  nand({a}, {b}) = {nand(a, b)}")

    print("\n=== NOT gate — NAND with tied inputs (Section 2) ===")
    for a in (0, 1):
        print(f"  not_gate({a}) = {not_gate(a)}")

    print("\n=== Buffer — two NANDs in series (Section 2) ===")
    for a in (0, 1):
        print(f"  buffer_gate({a}) = {buffer_gate(a)}")

    print("\n=== SR Latch — cross-coupled NANDs (Section 3) ===")
    latch = SRLatch()
    scenarios = [
        (0, 1, "Set   (S̄=0, R̄=1)"),
        (1, 1, "Hold  (S̄=1, R̄=1)"),
        (1, 0, "Reset (S̄=1, R̄=0)"),
        (1, 1, "Hold  (S̄=1, R̄=1)"),
    ]
    for s_bar, r_bar, label in scenarios:
        q, q_bar = latch.apply(s_bar, r_bar)
        print(f"  {label}  ->  Q={q}, Q̄={q_bar}")

    print("\n=== Forbidden state guard (Section 3 / AC-7) ===")
    try:
        latch.apply(0, 0)
    except ValueError as exc:
        print(f"  ValueError raised as expected: {exc}")
