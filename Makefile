VERILATOR ?= verilator
NODE ?= node
.PHONY: lint test
lint:
	$(VERILATOR) --lint-only --timing -Wno-fatal --top-module qr_decomp rtl/QR_decomp_solver.v
test:
	$(NODE) --test tests/*.test.js
