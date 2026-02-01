# paths

BUILD_DIR      = build
FTH_DIR        = w4
WAT_DIR        = wat
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


# flags

DEBUG ?= 0

ifeq ($(DEBUG),1)
M4_FLAGS       = -P -DDEBUG
FTH_FILTER     = cat
WASMOPT_FLAGS  = -O0 --enable-multivalue --enable-bulk-memory-opt
else
M4_FLAGS       = -P -DRELEASE
FTH_FILTER     = awk -f minify-filter.awk | awk -f minify-collapse.awk
WASMOPT_FLAGS  = -O4 --enable-multivalue --enable-bulk-memory-opt --converge
endif

NODE_FLAGS     = --disable-warning=ExperimentalWarning
WAT2WASM_FLAGS =

# tools w/ flags

M4_EXE         = m4 $(M4_FLAGS)
NODE_EXE       = node $(NODE_FLAGS) w4.js
OPT_EXE        = wasm-opt $(WASMOPT_FLAGS)
WAT_EXE        = wat2wasm $(WAT2WASM_FLAGS)

# targets

.PHONY: all run clean check
all: $(FTH_GEN) $(WASM_GEN_OPT)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# forth m4 expand
$(FTH_GEN): $(FTH_SRC) | $(BUILD_DIR)
	$(M4_EXE) -I$(FTH_DIR) $(FTH_ENTRY) | $(FTH_FILTER) > $@

# forth -> wat
$(WAT_FTH_GEN): $(FTH_GEN)
	python3 wat-forth.py $(FTH_GEN) $@

# wat m4 expand
$(WAT_GEN): $(WAT_FTH_GEN) $(WAT_SRC) | $(BUILD_DIR)
	$(M4_EXE) -I$(WAT_DIR) $(WAT_ENTRY) > $@

# wat -> wasm
$(WASM_GEN): $(WAT_GEN)
	$(WAT_EXE) $< -o $@

# optimize
$(WASM_GEN_OPT): $(WASM_GEN)
	$(OPT_EXE) $< -o $@

# cleanup build
clean:
	rm -rf $(BUILD_DIR)

# run tests
check-lib: $(FTH_GEN) $(WASM_GEN_OPT) $(TEST_LIB)
	$(NODE_EXE) $(TEST_LIB)

check-std: $(FTH_GEN) $(WASM_GEN_OPT) $(TEST_STD)
	$(NODE_EXE) $(TEST_STD) <test/forth2012-test-input.txt

check: check-lib check-std
