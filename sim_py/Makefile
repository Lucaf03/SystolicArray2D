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

# If local .venv exists but is not yet in PATH, re-execute make with updated PATH
# This ensures that $(shell ...) calls inside cocotb's Makefile.sim find cocotb-config and the venv's python
ifneq ($(wildcard $(VENV_BIN)/cocotb-config),)
    ifeq ($(findstring $(VENV_BIN),$(PATH)),)
        ifeq ($(MAKECMDGOALS),)
            .PHONY: __default_run
            __default_run:
		@PATH="$(VENV_BIN):$$PATH" $(MAKE) -f $(firstword $(MAKEFILE_LIST))
            all: __default_run
        else
            %:
		@PATH="$(VENV_BIN):$$PATH" $(MAKE) -f $(firstword $(MAKEFILE_LIST)) $@
        endif
        _RE_EXEC := 1
    endif
endif

ifndef _RE_EXEC

VERILOG_SOURCES += $(PWD)/../RTL/pe.sv
VERILOG_SOURCES += $(PWD)/../RTL/sys.sv

TOPLEVEL = sys
MODULE = test_sys

COMPILE_ARGS += -sv
SIM_ARGS += -t 1ps -voptargs="+acc"

COCOTB_CONFIG ?= cocotb-config
COCOTB_MAKEFILES := $(shell $(COCOTB_CONFIG) --makefiles 2>/dev/null)

ifeq ($(COCOTB_MAKEFILES),)
$(error cocotb is not installed or not in PATH! Please run './run.sh' (which automatically sets up the environment) or activate your virtual environment)
endif

include $(COCOTB_MAKEFILES)/Makefile.sim

# Additional cleanup for simulator logs, waveforms, reports, and caches
clean::
	@echo "Cleaning simulation artifacts in sim_py/..."
	rm -rf sim_build transcript results.xml modelsim.ini *.wlf *.vcd *.log __pycache__ .pytest_cache
	@echo "Cleanup completed."

endif
endif
