# paths

BUILD_DIR      = build
FTH_DIR        = w4
WAT_DIR        = wat
SCRIPT_DIR     = scripts
TEST_DIR       = test

FTH_ENTRY      = $(FTH_DIR)/w4.f
FTH_GEN        = $(BUILD_DIR)/w4.f
FTH_SRC       := $(shell find $(FTH_DIR) -type f -name '*.f' -print)

WAT_ENTRY      = $(WAT_DIR)/main.wat
WAT_GEN        = $(BUILD_DIR)/w4.wat
WAT_FTH_GEN    = $(BUILD_DIR)/w4-forth.wat
WAT_SRC       := $(shell find $(WAT_DIR) -type f -name '*.wat' -print)

WASM_GEN       = $(BUILD_DIR)/w4.wasm
WASM_GEN_OPT   = $(BUILD_DIR)/w4-opt.wasm

TEST_STD       = $(TEST_DIR)/forth2012-test-suite.f
TEST_LIB       = $(TEST_DIR)/w4-test-suite.f

SCR_AWK_FIL    = $(SCRIPT_DIR)/minify-filter.awk
SCR_AWK_COL    = $(SCRIPT_DIR)/minify-collapse.awk
SCR_PYT_FTH    = $(SCRIPT_DIR)/embed-forth.py


# flags

DEBUG ?= 0

NODE_FLAGS     = --disable-warning=ExperimentalWarning
WASMOPT_BFLAGS = --enable-multivalue --enable-bulk-memory-opt

ifeq ($(DEBUG),1)
M4_FLAGS       = -P -DDEBUG
FTH_FILTER     = cat
WASMOPT_FLAGS  = $(WASMOPT_BFLAGS) -O0
else
M4_FLAGS       = -P -DRELEASE
FTH_FILTER     = awk -f $(SCR_AWK_FIL) | awk -f $(SCR_AWK_COL)
WASMOPT_FLAGS  = $(WASMOPT_BFLAGS) -O4 --converge
endif


# tools w/ flags

M4_EXE         = m4 $(M4_FLAGS)
NODE_EXE       = node $(NODE_FLAGS) w4.js
OPT_EXE        = wasm-opt $(WASMOPT_FLAGS)
WAT_EXE        = wat2wasm
PY_EXE         = python3

# targets

.PHONY: all clean check
all: $(FTH_GEN) $(WASM_GEN_OPT)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# forth m4 expand
$(FTH_GEN): $(FTH_SRC) | $(BUILD_DIR)
	$(M4_EXE) -I$(FTH_DIR) $(FTH_ENTRY) | $(FTH_FILTER) > $@

# forth -> wat
$(WAT_FTH_GEN): $(FTH_GEN)
	$(PY_EXE) $(SCR_PYT_FTH) $(FTH_GEN) $@

# wat m4 expand
$(WAT_GEN): $(WAT_FTH_GEN) $(WAT_SRC) | $(BUILD_DIR)
	$(M4_EXE) -I$(WAT_DIR) $(WAT_ENTRY) > $@

# wat -> wasm
$(WASM_GEN): $(WAT_GEN)
	$(WAT_EXE) $< -o $@

# optimize
$(WASM_GEN_OPT): $(WASM_GEN)
	$(OPT_EXE) $< -o $@

# run tests
check-lib: $(FTH_GEN) $(WASM_GEN_OPT) $(TEST_LIB)
	$(NODE_EXE) $(TEST_LIB)

check-std: $(FTH_GEN) $(WASM_GEN_OPT) $(TEST_STD)
	$(NODE_EXE) $(TEST_STD) <test/forth2012-test-input.txt

check: check-lib check-std

# cleanup build
clean:
	rm -rf $(BUILD_DIR)
