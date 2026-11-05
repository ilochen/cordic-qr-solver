VERILATOR ?= verilator
NODE ?= node
.PHONY: lint test
lint:
	$(VERILATOR) --lint-only --timing -Wno-fatal --top-module qr_decomp rtl/QR_decomp_solver.v
test:
	$(NODE) --test tests/*.test.js

.PHONY: rtl-sim
rtl-sim:
	mkdir -p build
	cp vectors/testcases.txt build/testcases.txt
	$(VERILATOR) --binary --timing -Wno-fatal --Mdir build/obj --top-module qr_decomp_tb rtl/QR_decomp_solver.v tb/QR_decomp_tb.v
	cd build && ./obj/Vqr_decomp_tb > rtl-results.txt
	python3 tests/check_vectors.py build/testcases.txt build/rtl-results.txt
