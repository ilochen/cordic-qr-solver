"""Check output count and solution residuals against the actual streamed vectors."""
import math
import re
import sys
from pathlib import Path

words = Path(sys.argv[1]).read_text().split()
assert len(words) == 2000 and all(re.fullmatch('[01]{25}', w) for w in words)
values = [(int(w, 2) - ((1 << 25) if w[0] == '1' else 0)) / 2**19 for w in words]
outputs = re.findall(r'Sol\s+(\d+) : x1: (\S+), x2: (\S+), x3: (\S+), x4: (\S+)', Path(sys.argv[2]).read_text())
assert len(outputs) == 100, f'expected 100 output vectors, saw {len(outputs)}'
def solve_reference(matrix, rhs):
    """Double precision Gaussian elimination with partial pivoting."""
    a = [list(row) + [y] for row, y in zip(matrix, rhs)]
    for col in range(4):
        pivot = max(range(col, 4), key=lambda i: abs(a[i][col]))
        a[col], a[pivot] = a[pivot], a[col]
        scale = a[col][col]
        assert abs(scale) > 1e-12
        a[col] = [v / scale for v in a[col]]
        for row in range(4):
            if row != col:
                multiplier = a[row][col]
                a[row] = [v - multiplier * ref for v, ref in zip(a[row], a[col])]
    return [row[-1] for row in a]

residuals = []
solution_errors = []
for n, (label, *solution) in enumerate(outputs):
    assert int(label) == n + 1
    x = list(map(float, solution))
    case = values[20*n:20*n+20]
    reference = solve_reference([case[4*r:4*r+4] for r in range(4)], case[16:])
    solution_errors.append(math.sqrt(sum((a-b)**2 for a,b in zip(x, reference))/4))
    residuals.append(math.sqrt(sum((sum(case[4*r+c]*x[c] for c in range(4))-case[16+r])**2 for r in range(4))/4))
print(f'{len(outputs)} RTL solutions; max RMS residual ||Ax-y||/2 = {max(residuals):.6g}')
assert all(r < 0.01 for r in residuals), 'residual above 0.01'

print(f'Max solution RMSE against the quantized input system = {max(solution_errors):.6g}')
assert all(e <= 0.001 for e in solution_errors), 'solution RMSE above 0.001'
