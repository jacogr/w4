# tools

M4        = m4
WAT2WASM  = wat2wasm
WASMOPT   = wasm-opt


# paths

WAT_DIR   = wat
BUILD     = build

ENTRY_WAT = $(WAT_DIR)/main.wat
GEN_WAT   = $(BUILD)/w4.wat
SRC_WATS  := $(wildcard $(WAT_DIR)/*.wat)

WASM      = $(BUILD)/w4.wasm
WASMOPTED = $(BUILD)/w4-opt.wasm


# flags

DEBUG ?= 0

ifeq ($(DEBUG),1)
M4_FLAGS      = -P -I$(WAT_DIR) -DDEBUG
WASMOPT_FLAGS = -O0 --enable-multivalue --enable-bulk-memory-opt
else
M4_FLAGS      = -P -I$(WAT_DIR) -DRELEASE
WASMOPT_FLAGS = -O4 --enable-multivalue --enable-bulk-memory-opt --converge
endif


# targets

.PHONY: all run clean
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

clean:
	rm -rf $(BUILD)
