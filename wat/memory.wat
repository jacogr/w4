
(;

	memory.wat

	Memory layout.

;)

	;; 64 pages in size ... each page being 64k (0x10000)
	;; total 4MB
	(memory (export "memory") 64 64)

	;; first 256 bytes of memory intentionally left empty
	;; $SIZEOF_MEMORY_RO (here) = $PTR_ALLOC (below)
	(global $SIZEOF_MEMORY_RO  i32 (i32.const 0x00000100)) ;; first writable location
	(global $SIZEOF_MEMORY_MAX i32 (i32.const 0x00400000)) ;; page count * 64k in bytes

	;; pointer area - all pointer offsets are stored here, as
	;; constants and are accessible via memory location in the
	;; interpreter
	(global $PTR_ALLOC         i32 (i32.const 0x0100))
	(global $PTR_ALLOC_MIN     i32 (i32.const 0x0104))
	(global $PTR_ALLOC_MAX     i32 (i32.const 0x0108))
	(global $PTR_SRC_ID        i32 (i32.const 0x0110))
	(global $PTR_PTR_LINE_OFF  i32 (i32.const 0x0114))
	(global $PTR_LINE_IOV      i32 (i32.const 0x0118))
	(global $PTR_PTR_TOK_CMP   i32 (i32.const 0x0120)) ;; current compiled token
	(global $PTR_PTR_TOK_EXE   i32 (i32.const 0x0124)) ;; current executing token
	(global $PTR_PTR_TOK_NXT   i32 (i32.const 0x0128)) ;; next executing token
	(global $PTR_STATE         i32 (i32.const 0x0130))
	(global $PTR_BASE          i32 (i32.const 0x0134))
	(global $PTR_PTR_STACK_DAT i32 (i32.const 0x0140))
	(global $PTR_PTR_STACK_RET i32 (i32.const 0x0144))
	(global $PTR_PTR_STACK_SRC i32 (i32.const 0x0148))
	(global $PTR_WID_ORIG      i32 (i32.const 0x0150))
	(global $PTR_WID_CURR      i32 (i32.const 0x0154))
	(global $PTR_PTR_WID_LIST  i32 (i32.const 0x0158))
	(global $PTR_WID_COUNT     i32 (i32.const 0x015c))
	(global $PTR_LOC_VALUE_AT  i32 (i32.const 0x0160)) ;; local value offset
	(global $PTR_LOC_WID  	   i32 (i32.const 0x0164))
	;; next layout starting at 512 (0x0200)

	;; init for known values
	(data (i32.const 0x0134) "\0a") ;; base = 10
	(data (i32.const 0x015c) "\01") ;; one (original) wordlist

	;; general scratchpad area is available at the start of the memory
	;; (we further break up into general areas)
	(global $PTR_PRI_EMIT_STR i32 (i32.const 0x0200)) ;; scratch for emit string, 64 total
	(global $PTR_PRI_EMIT_RES i32 (i32.const 0x0240)) ;; scratch for emit result, 64 total
	(global $PTR_PRI_IOV      i32 (i32.const 0x0280)) ;; 256 total
	;; next layout at 980 (0x03d4), memory in-between is sparse for future usage

	;; text definitions as used
	(global $PTR_DO_MARK_TEXT i32 (i32.const  980))
	(global $PTR_DO_EXEC_TEXT i32 (i32.const  990)) ;; location of the jump string
	(global $PTR_NATIVE_TEXT  i32 (i32.const 1000)) ;; location of the first native, "exit" (1000)
	(global $PTR_EXCEP_CODE   i32 (i32.const 1264)) ;; exception lookup table
	(global $PTR_EXCEP_TEXT   i32 (i32.const 1424)) ;; exception text, 1264 + 160
