
(;

	memory.wat

	Memory layout and maagement thereof.

;)

	;; 10 pages in size ... each page being 64k (0x10000)
	;; "640kb should be enough for everybody" ...
	(memory (export "memory") 16)

	;; first 256 bytes of memory intentionally left empty
	;; $SIZEOF_MEMORY_RO (here) = $PTR_ALLOC (below)
	(global $SIZEOF_MEMORY_RO  i32 (i32.const 0x00000100)) ;; first writable location
	(global $SIZEOF_MEMORY_MAX i32 (i32.const 0x00100000)) ;; page count * 64k in bytes

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
	(global $PTR_PRI_IN       i32 (i32.const 0x0280)) ;; scatch for in values, 64 total
	(global $PTR_PRI_IOV      i32 (i32.const 0x02c0)) ;; 256 total
	;; next layout at 960 (0x03c0), memory in-between is sparse for future usage

	;; text definitions as used
	(global $PTR_W4_FILES     i32 (i32.const  960)) ;; files to execute at startup
	(global $PTR_DO_MARK_TEXT i32 (i32.const  980))
	(global $PTR_DO_EXEC_TEXT i32 (i32.const  990)) ;; location of the jump string
	(global $PTR_NATIVE_TEXT  i32 (i32.const 1000)) ;; location of the first native, "exit" (1000)
	(global $PTR_EXCEP_CODE   i32 (i32.const 1232)) ;; exception lookup table
	(global $PTR_EXCEP_TEXT   i32 (i32.const 1392)) ;; exception text, 1232 + 160

	;;
	;; Allocates a section of memory and returns the address
	;;
	(func $__alloc (export "alloc") (param $size i32) (result i32)
		;; allocate w/ address alignment
		(call $__alloc_inner
			(i32.and
				(i32.add
					(i32.load (global.get $PTR_ALLOC))
					(i32.const 3))
				(i32.const -4))
			(local.get $size))
	)

	;;
	;; Internal function with pointer & address allocation
	;;
	(func $__alloc_inner (param $ptr i32) (param $size i32) (result i32)
		(local $nxt i32)

		;; ensure max memory > next pointer, -23 address alignment exception
		(call $__assert
			(i32.gt_u
				(global.get $SIZEOF_MEMORY_MAX)
				(local.tee $nxt
					(i32.add (local.get $ptr) (local.get $size))))
			(i32.const -23))

		;; update the next pointer with the calculated size
		(i32.store (global.get $PTR_ALLOC) (local.get $nxt))

		;; return pointer to allocated area
		local.get $ptr
	)

	;;
	;; Allocate a new known structure, setting the flags directly
	;; (useful for lists, list items and xt)
	;;
	(func $__new (param $size i32) (param $flags i32) (result i32)
		(local $ptr i32)

		;; create item, set flags
		(call $__val_set_flags
			(local.tee $ptr (call $__alloc (local.get $size)))
			(local.get $flags))

		;; return pointer
		local.get $ptr
	)
