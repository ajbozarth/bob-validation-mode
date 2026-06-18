def matrix_multiply(a: list[list[float]], b: list[list[float]]) -> list[list[float]]:
    """Multiply two matrices and return the result.

    Args:
        a: First matrix (m x n)
        b: Second matrix (n x p)

    Returns:
        Result matrix (m x p)

    Raises:
        ValueError: If the matrices have incompatible dimensions.
    """
    rows_a, cols_a = len(a), len(a[0])
    rows_b, cols_b = len(b), len(b[0])

    if cols_a != rows_b:
        raise ValueError(
            f"Incompatible dimensions: ({rows_a}x{cols_a}) @ ({rows_b}x{cols_b})"
        )

    result = [[0.0] * cols_b for _ in range(rows_a)]
    for i in range(rows_a):
        for j in range(cols_b):
            for k in range(cols_a):
                result[i][j] += a[i][k] * b[k][j]

    return result


def print_matrix(matrix: list[list[float]], name: str = "Matrix") -> None:
    print(f"{name}:")
    for row in matrix:
        print("  ", row)
    print()


if __name__ == "__main__":
    A = [
        [1, 2, 3],
        [4, 5, 6],
    ]

    B = [
        [7,  8],
        [9,  10],
        [11, 12],
    ]

    print_matrix(A, "A (2x3)")
    print_matrix(B, "B (3x2)")

    C = matrix_multiply(A, B)
    print_matrix(C, "C = A @ B (2x2)")
