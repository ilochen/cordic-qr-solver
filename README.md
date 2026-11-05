# CORDIC QR Linear Solver

A fixed-point 4 × 4 solver integrating a CORDIC systolic QR array and folded back-substitution. The architecture reuses vectoring directions across columns, aligns operands with inter-PE registers, and overlaps coefficient loading with triangular solution through ping-pong register banks.

[Interactive architecture and design decisions](https://ilochen.github.io/projects/cordic-qr-solver/)

## Source layout

- `rtl/QR_decomp_solver.v`: integrated implementation; top module `qr_decomp`. Contains CORDIC, shift/add, back-substitution, multiplier, and divider modules.
- `rtl/variants/QR_decomp.v`: standalone QR implementation.
- `rtl/variants/BackSub.v`: standalone single-multiplier back-substitution variant.
- `model/dsp_final.m`: MATLAB fixed-point numerical model and test-vector export.
- `model/generate_patterns.m`: reproducible input generator matching the model's expected MAT-file schema.
- `assets/` and `tests/`: executable architectural reference models and numerical/dataflow checks used by the portfolio.

Compile the integrated source alone: the standalone variants define overlapping module names. The report's numerical study uses 18 CORDIC stages and a 25-bit QR word. The supplied integrated RTL defaults to DATA_WIDTH=22; preserve or explicitly override parameters when comparing configurations.

## Run

```sh
make lint          # Verilator source elaboration
make rtl-sim       # integrated RTL, 100 streamed systems, checked against a double-precision solve
npm test           # Node.js 22+, no dependencies
```

For MATLAB with Fixed-Point Designer, change to `model/` and run `dsp_final`. The supplied `qr_test_patterns.mat` is included. The script writes 25-bit fixed-point input words and evaluates the 18-stage solver. Run `generate_patterns` separately to regenerate seeded data. The alternative script under `model/archive/` selects 17 stages and loads `input_patterns_updated.mat`; run it from that directory to avoid overwriting the primary model outputs.

The source testbench instantiates DATA_WIDTH=25. `make rtl-sim` streams the supplied `vectors/testcases.txt` and checks 100 solution vectors. The driver disables the original simulator-specific FSDB calls by default. `constraints/qr_solver.sdc` preserves the original 20 ns synthesis target and references external libraries by name. The 7.5 ns RTL stimulus clock is a simulation setting, not a measured implementation frequency.

## Design

QR implements rotations through shift/add stages and output gain correction. Retiming preserves producer–consumer alignment through the array. Back-substitution shares three product lanes and one divider; bank selection separates the next coefficient block from the current solve.

See [validation notes](docs/validation.md) for the checked artifacts and compiler diagnostics.
