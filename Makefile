# paths

DIR_BUILD      = build
DIR_FTH        = w4
DIR_WAT        = wat
DIR_SCR        = scripts
DIR_TEST       = test

FTH_ENTRY      = $(DIR_FTH)/w4.f
FTH_GEN        = $(DIR_BUILD)/w4.f
FTH_SRC       := $(shell find $(DIR_FTH) -type f -name '*.f' -print)

WAT_ENTRY      = $(DIR_WAT)/main.wat
WAT_GEN        = $(DIR_BUILD)/w4.wat
WAT_FTH_GEN    = $(DIR_BUILD)/w4-forth.wat
WAT_SRC       := $(shell find $(DIR_WAT) -type f -name '*.wat' -print)

WASM_GEN       = $(DIR_BUILD)/w4.wasm
WASM_GEN_OPT   = $(DIR_BUILD)/w4-opt.wasm

TEST_STD       = $(DIR_TEST)/forth2012-test-suite.f
TEST_LIB       = $(DIR_TEST)/w4-test-suite.f

SCR_AWK_FIL    = $(DIR_SCR)/minify-filter.awk
SCR_AWK_COL    = $(DIR_SCR)/minify-collapse.awk
SCR_PYT_FTH    = $(DIR_SCR)/embed-forth.py


# flags

DEBUG ?= 0

FLAGS_NODE     = --disable-warning=ExperimentalWarning
FLAGS_OPT_BASE = --enable-multivalue --enable-bulk-memory-opt

ifeq ($(DEBUG),1)
FLAGS_M4       = -P -DDEBUG
FTH_FILTER     = cat
FLAGS_OPT      = $(FLAGS_OPT_BASE) -O0
else
FLAGS_M4       = -P -DRELEASE
FTH_FILTER     = awk -f $(SCR_AWK_FIL) | awk -f $(SCR_AWK_COL)
FLAGS_OPT      = $(FLAGS_OPT_BASE) -O4 --converge
endif


# tools w/ flags

EXE_M4         = m4 $(FLAGS_M4)
EXE_NODE       = node $(FLAGS_NODE) w4.js
EXE_OPT        = wasm-opt $(FLAGS_OPT)
EXE_WAT        = wat2wasm
EXE_PYT        = python3

# targets

.PHONY: all clean check
all: $(FTH_GEN) $(WASM_GEN_OPT)

$(DIR_BUILD):
	mkdir -p $(DIR_BUILD)

# forth m4 expand
$(FTH_GEN): $(FTH_SRC) | $(DIR_BUILD)
	$(EXE_M4) -I$(DIR_FTH) $(FTH_ENTRY) | $(FTH_FILTER) > $@

# forth -> wat
$(WAT_FTH_GEN): $(FTH_GEN)
	$(EXE_PYT) $(SCR_PYT_FTH) $(FTH_GEN) $@

# wat m4 expand
$(WAT_GEN): $(WAT_FTH_GEN) $(WAT_SRC) | $(DIR_BUILD)
	$(EXE_M4) -I$(DIR_WAT) $(WAT_ENTRY) > $@

# wat -> wasm
$(WASM_GEN): $(WAT_GEN)
	$(EXE_WAT) $< -o $@

# optimize
$(WASM_GEN_OPT): $(WASM_GEN)
	$(EXE_OPT) $< -o $@

# run tests
check-lib: $(FTH_GEN) $(WASM_GEN_OPT) $(TEST_LIB)
	$(EXE_NODE) $(TEST_LIB)

check-std: $(FTH_GEN) $(WASM_GEN_OPT) $(TEST_STD)
	$(EXE_NODE) $(TEST_STD) <test/forth2012-test-input.txt

check: check-lib check-std

# cleanup build
clean:
	rm -rf $(DIR_BUILD)
