# tools

M4        = m4
WAT2WASM  = wat2wasm
WASMOPT   = wasm-opt
NODE      = node


# paths

BUILD_DIR    = build
FTH_DIR      = w4
WAT_DIR      = wat
TEST_DIR     = test

FTH_ENTRY    = $(FTH_DIR)/w4.f
FTH_GEN      = $(BUILD_DIR)/w4.f
FTH_SRC     := $(shell find $(FTH_DIR) -type f -name '*.f' -print)

WAT_ENTRY    = $(WAT_DIR)/main.wat
WAT_GEN      = $(BUILD_DIR)/w4.wat
WAT_SRC     := $(shell find $(WAT_DIR) -type f -name '*.wat' -print)

WASM_GEN     = $(BUILD_DIR)/w4.wasm
WASM_GEN_OPT = $(BUILD_DIR)/w4-opt.wasm

TEST_STD     = $(TEST_DIR)/forth2012-test-suite.f
TEST_W4      = $(TEST_DIR)/library-test-suite.f


# flags

DEBUG ?= 0

ifeq ($(DEBUG),1)
M4_FLAGS      = -P -DDEBUG
WASMOPT_FLAGS = -O0 --enable-multivalue --enable-bulk-memory-opt
else
M4_FLAGS      = -P -DRELEASE
WASMOPT_FLAGS = -O4 --enable-multivalue --enable-bulk-memory-opt --converge
endif

NODE_FLAGS = --disable-warning=ExperimentalWarning


# targets

.PHONY: all run clean check
all: $(FTH_GEN) $(WASM_GEN_OPT)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# forth m4 expand
$(FTH_GEN): $(FTH_SRC) | $(BUILD_DIR)
	$(M4) $(M4_FLAGS) -I$(FTH_DIR) $(FTH_ENTRY) > $@

# wat m4 expand
$(WAT_GEN): $(WAT_SRC) | $(BUILD_DIR)
	$(M4) $(M4_FLAGS) -I$(WAT_DIR) $(WAT_ENTRY) > $@

# wat -> wasm
$(WASM_GEN): $(WAT_GEN)
	$(WAT2WASM) $< -o $@

# optimize
$(WASM_GEN_OPT): $(WASM_GEN)
	$(WASMOPT) $(WASMOPT_FLAGS) $< -o $@

# cleanup build
clean:
	rm -rf $(BUILD_DIR)

# run tests
check: $(FTH_GEN) $(WASM_GEN_OPT) $(TEST_STD)
	$(NODE) $(NODE_FLAGS) w4.js $(TEST_W4)
	$(NODE) $(NODE_FLAGS) w4.js $(TEST_STD) <test/forth2012-test-input.txt
