# Makefile - improved output and safety

SHELL := /bin/bash

VCS ?= vcs
VERDI ?= verdi
TOP ?= tb

SRC_DIR ?= ./
FILELIST ?=
GENERATED_FILELIST := filelist.f

ifeq ($(strip $(FILELIST)),)
	USE_FILELIST := $(GENERATED_FILELIST)
else
	USE_FILELIST := $(FILELIST)
endif

ifneq ($(strip $(BUILD_DIR)),)
  BUILD_DIR := $(abspath $(BUILD_DIR))
else
  ifneq ($(strip $(PWD)),$(strip $(CURDIR)))
    # Called from a different shell cwd (e.g. cd b && make -C ..)
    BUILD_DIR := $(abspath $(PWD))
  else
    # Normal case: default to repo-root/build
    BUILD_DIR := $(abspath $(CURDIR)/build)
  endif
endif

COMPILE_LOG := $(BUILD_DIR)/compile.log
SIMV := $(BUILD_DIR)/simv

# VCS flags (use COMPILE_LOG and BUILD_DIR variables)
VCS_FLAGS ?= -top $(TOP) \
	+libext+.v +libext+.sv +libext+.vc \
	-full64 -sverilog \
	-f $(USE_FILELIST) \
	-l $(COMPILE_LOG) \
	-debug_region=cell+encrypt -debug_acc+all \
	-timescale=1ns/1ps \
	-kdb \
	-o $(SIMV) \
	-Mdirectory=$(BUILD_DIR)/csrc

DOFILE ?= dump_fsdb.tcl

.PHONY: all compile sim run verdi clean help firmware
all: run

# ensure build dir exists
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Generate filelist, excluding build dir to avoid listing artifacts
$(GENERATED_FILELIST):
	@printf "==> Generating %s from %s ...$(NC)\n" "$(GENERATED_FILELIST)" "$(SRC_DIR)"
	@find $(SRC_DIR) -type f \( -name "*.sv" -o -name "*.v" \) -not -path "$(BUILD_DIR)/*" | sort > $(GENERATED_FILELIST)
	@printf "==> Wrote %s with %s entries.$(NC)\n" "$(GENERATED_FILELIST)" "$$(wc -l < $(GENERATED_FILELIST))"

.PHONY: compile
# only require generated filelist if we are using it
compile: $(if $(filter $(GENERATED_FILELIST),$(USE_FILELIST)),$(GENERATED_FILELIST)) $(BUILD_DIR)
	@printf "\n==> VCS compile (top=%s)$(NC)\n" "$(TOP)"
	@if [ ! -s "$(USE_FILELIST)" ]; then \
		printf "Error: filelist '%s' is empty or not found. Create it or set FILELIST variable.$(NC)\n" "$(USE_FILELIST)"; \
		exit 1; \
	fi
	@printf "Using filelist: %s (lines: %s)$(NC)\n" "$(USE_FILELIST)" "$$(wc -l < $(USE_FILELIST))"
	@printf "Build directory: %s$(NC)\n" "$(BUILD_DIR)"
	@echo "Command: $(VCS) [flags ...]" >/dev/null || true
	@set -o pipefail; $(VCS) $(VCS_FLAGS)
	@printf "==> VCS compile finished. See %s for details.$(NC)\n" "$(COMPILE_LOG)"

.PHONY: verdi
verdi: $(BUILD_DIR)
	@printf "==> Starting Verdi (dbdir: simv.daidir)$(NC)\n"
	@if ! command -v $(VERDI) >/dev/null 2>&1; then \
		printf "Error: '%s' not found in PATH. Install Verdi or set VERDI variable.$(NC)\n" "$(VERDI)"; exit 1; \
	fi
	@cd $(BUILD_DIR) && nohup $(VERDI) -dbdir simv.daidir >/dev/null 2>&1 & disown || true
	@printf "==> Verdi started (background).$(NC)\n"

TIMEOUT ?= 
MACROS = +BIN=$(BIN) \
		+SPDLOG_LEVEL_SV=$(SPDLOG_LEVEL_SV) \
		+TIMEOUT=$(TIMEOUT)

VCS_ARGS ?=
VCS_ARGS += +firmware=$(firmware)

.PHONY: sim
sim:
	@if [ ! -x "$(SIMV)" ]; then \
		printf "Error: '%s' not found or not executable. Run 'make compile' first.$(NC)\n" "$(SIMV)"; exit 1; \
	fi
	@printf "==> Running simulation: %s$(NC)\n" "$(SIMV)"
	@cd $(BUILD_DIR) && ./simv -ucli -do ../$(DOFILE) -no_save $(MACROS) $(VCS_ARGS)
	@printf "==> Simulation finished (check wave/database).$(NC)\n"

.PHONY: run
run: compile sim

.PHONY: clean
clean:
	@printf "==> Cleaning generated simulation files in '%s'...$(NC)\n" "$(BUILD_DIR)"
	@rm -rf $(BUILD_DIR)
	@printf "==> Clean done.$(NC)\n"

.PHONY: help
help:
	@printf "Available targets:$(NC)\n"
	@printf "  all (default)   - compile + run\n"
	@printf "  compile         - run vcs to build simv (creates %s)\n" "$(BUILD_DIR)"
	@printf "  sim             - run ./simv (requires compile done)\n"
	@printf "  run             - compile then sim\n"
	@printf "  verdi           - start Verdi GUI (background)\n"
	@printf "  clean           - remove generated files\n"
	@printf "\nCommon variables you can override on the make command line:\n"
	@printf "  TOP, SRC_DIR, FILELIST, BUILD_DIR, VCS, VERDI\n"
	@printf "\nExamples:\n"
	@printf "  1. make run TOP=tb BIN=test.bin fsdb_file=test TIMEOUT=1000\n"
	@printf "  2. mkdir build\n\tcd build\n\tmake -C .. compile\n\tmake -C .. sim\n"
	@printf "  3. make compile BUILD_DIR=build_xxx\n"
