SIM ?= modelsim
TOPLEVEL_LANG ?= verilog

PWD = $(shell pwd)
VENV_BIN := $(PWD)/../.venv/bin

# If target is clean, execute cleanup directly without requiring cocotb environment
ifeq ($(MAKECMDGOALS),clean)
.PHONY: clean
clean:
	@echo "Cleaning simulation artifacts in sim_py/..."
	rm -rf sim_build transcript results.xml modelsim.ini *.wlf *.vcd *.log __pycache__ .pytest_cache
	@echo "Cleanup completed."
else

VERILOG_SOURCES += $(PWD)/../RTL/pe.sv
VERILOG_SOURCES += $(PWD)/../RTL/sys.sv

TOPLEVEL = sys
MODULE = test_sys

COMPILE_ARGS += -sv
SIM_ARGS += -t 1ps -voptargs="+acc"

# Auto-detect local virtualenv if present, otherwise use environment's cocotb-config
ifneq ($(wildcard $(VENV_BIN)/cocotb-config),)
    export PATH := $(VENV_BIN):$(PATH)
    COCOTB_CONFIG ?= $(VENV_BIN)/cocotb-config
else
    COCOTB_CONFIG ?= cocotb-config
endif

include $(shell $(COCOTB_CONFIG) --makefiles)/Makefile.sim

# Additional cleanup for simulator logs, waveforms, reports, and caches
clean::
	@echo "Cleaning simulation artifacts in sim_py/..."
	rm -rf sim_build transcript results.xml modelsim.ini *.wlf *.vcd *.log __pycache__ .pytest_cache
	@echo "Cleanup completed."

endif
