# tools

M4        = m4
WAT2WASM  = wat2wasm
WASMOPT   = wasm-opt
NODE      = node


# paths

WAT_DIR   = wat
BUILD     = build

ENTRY_WAT = $(WAT_DIR)/main.wat
GEN_WAT   = $(BUILD)/w4.wat
SRC_WATS  := $(shell find $(WAT_DIR) -type f -name '*.wat' -print)

WASM      = $(BUILD)/w4.wasm
WASMOPTED = $(BUILD)/w4-opt.wasm

TESTS_STD = test/forth2012-test-suite.f
TESTS_W4  = test/w4.f


# flags

DEBUG ?= 0

ifeq ($(DEBUG),1)
M4_FLAGS      = -P -I$(WAT_DIR) -DDEBUG
WASMOPT_FLAGS = -O0 --enable-multivalue --enable-bulk-memory-opt
else
M4_FLAGS      = -P -I$(WAT_DIR) -DRELEASE
WASMOPT_FLAGS = -O4 --enable-multivalue --enable-bulk-memory-opt --converge
endif

NODE_FLAGS = --disable-warning=ExperimentalWarning


# targets

.PHONY: all run clean check
all: $(WASMOPTED)

$(BUILD):
	mkdir -p $(BUILD)

# m4 expand
$(GEN_WAT): $(SRC_WATS) | $(BUILD)
	$(M4) $(M4_FLAGS) $(ENTRY_WAT) > $@

# wat -> wasm
$(WASM): $(GEN_WAT)
	$(WAT2WASM) $< -o $@

# optimize
$(WASMOPTED): $(WASM)
	$(WASMOPT) $(WASMOPT_FLAGS) $< -o $@

# cleanup build
clean:
	rm -rf $(BUILD)

# run tests
check: $(WASMOPTED) $(TESTS_STD)
	$(NODE) $(NODE_FLAGS) w4.js $(TESTS_W4)
	$(NODE) $(NODE_FLAGS) w4.js $(TESTS_STD) <test/forth2012-test-input.txt
