# Validation

The original RTL is preserved as supplied. `make lint` elaborates the design with Verilator; `-Wno-fatal` retains compiler warnings in the output.

Observed warning classes: CASEINCOMPLETE, UNOPTFLAT, WIDTHEXPAND, WIDTHTRUNC.

`npm test` checks the accompanying architectural reference models against independent numerical or sequential references. These tests validate model behavior; RTL simulation and synthesis are separate flows.

## RTL regression

Run `make rtl-sim` with Verilator 5, a C++ toolchain and Python 3. The original integrated RTL, testbench and 2,000 signed 25-bit stimulus words produced 100 solutions locally with Verilator 5.052. Against a double-precision solve of the decoded inputs, maximum solution RMSE was 0.000535664. Maximum RMS residual was 0.0000340539. The result uses the vectors distributed with the RTL and the six-decimal outputs printed by the testbench.
