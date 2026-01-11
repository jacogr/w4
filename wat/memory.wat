
(;

	memory.wat

	Memory layout and maagement thereof.

;)

	;; 10 pages in size ... each page being 64k (0x10000)
	;; "640kb should be enough for everybody" ...
	(memory (export "memory") 10)

	;; first 256 bytes of memory intentionally left empty
	;; $SIZEOF_MEMORY_RO (here) = $PTR_ALLOC (below)
	(global $SIZEOF_MEMORY_RO  i32 (i32.const 0x00100)) ;; first writable location
	(global $SIZEOF_MEMORY_MAX i32 (i32.const 0xA0000)) ;; page count * 64k in bytes

	;; pointer area - all pointer offsets are stored here, as
	;; constants and are accessible via memory location in the
	;; interpreter
	(global $PTR_ALLOC         i32 (i32.const 0x0100))
	(global $PTR_ALLOC_MIN   i32 (i32.const 0x0104))
	(global $PTR_ALLOC_MAX     i32 (i32.const 0x0108))
	(global $PTR_SRC_ID        i32 (i32.const 0x0110))
	(global $PTR_PTR_LINE_OFF  i32 (i32.const 0x0114))
	(global $PTR_LINE_IOV      i32 (i32.const 0x0118))
	(global $PTR_PTR_TOK_CMP   i32 (i32.const 0x0120)) ;; current compiled token
	(global $PTR_PTR_TOK_EXE   i32 (i32.const 0x0124)) ;; current executing token
	(global $PTR_PTR_DICT      i32 (i32.const 0x0128))
	(global $PTR_PTR_INCL      i32 (i32.const 0x012c)) ;; list of included files
	(global $PTR_PTR_STACK_DAT i32 (i32.const 0x0140))
	(global $PTR_PTR_STACK_RET i32 (i32.const 0x0144))
	(global $PTR_PTR_STACK_CTL i32 (i32.const 0x0148))
	(global $PTR_PTR_STACK_SRC i32 (i32.const 0x014c))
	(global $PTR_STATE         i32 (i32.const 0x0150))
	(global $PTR_BASE          i32 (i32.const 0x0154))
	(global $PTR_TMP           i32 (i32.const 0x0160)) ;; temp 16-bytes, don't rely on it
	(global $PTR_TMP_STR       i32 (i32.const 0x0170)) ;; temp 64-bytes, don't rely on it
	;; next layout starting at 512 (0x0200)

	;; init for known values
	(data (i32.const 0x0154) "\0a") ;; base = 10

	;; general scratchpad area is available at the start of the memory
	;; (we further break up into general areas)
	(global $PTR_PRI_EMIT_STR i32 (i32.const 0x0200)) ;; scratch for emit string, 32 total
	(global $PTR_PRI_EMIT_RES i32 (i32.const 0x0220)) ;; scratch for emit result, 16 total
	(global $PTR_PRI_IN       i32 (i32.const 0x0240)) ;; scatch for in values, 64 total
	(global $PTR_PRI_IOV      i32 (i32.const 0x0280)) ;; 64 total
	;; next layout at 960 (0x03c0), memory in-between is sparse for future usage

	;; text definitions as used
	(global $PTR_W4_FILES     i32 (i32.const  960)) ;; files to execute at startup
	(global $PTR_DO_MARK_TEXT i32 (i32.const  980))
	(global $PTR_DO_EXEC_TEXT i32 (i32.const  990)) ;; location of the jump string
	(global $PTR_NATIVE_TEXT  i32 (i32.const 1000)) ;; location of the first native, "exit" (1000)
	(global $PTR_EXCEP_CODE   i32 (i32.const 1232)) ;; exception lookup table
	(global $PTR_EXCEP_TEXT   i32 (i32.const 1392)) ;; exception text, 1232 + 160

	;;
	;; Calculate the required size for 4-byte alignment
	;;
	;;		((size + (1 << 2)) >> 2) << 2) is
	;;      ((size + 3) / 4) * 4)
	;;
	;; is the same as
	;;
	;;		((size + 4) & -4)
	;;
	(func $__alloc_align (param $size i32) (result i32)
		(i32.and
			(i32.add
				(local.get $size)
				(i32.const 3))
			(i32.const -4))
	)

	;;
	;; Allocates a section of memory and returns the address
	;;
	;; We ensure that we allocate in sizes evenly divisible by 16 bytes
	;; to allow for v128 alignment throughout. The 16-byte alignment also
	;; applies to the pointer.
	;;
	;; However Forth also has access to it, so alignment may be off, hence
	;; adjusting the pointer value as well. In that world thinking is around
	;; cells, which are 32-bit and allocation can happen at that level.
	;;
	(func $__alloc (export "alloc") (param $size i32) (result i32)
		(local $nxt i32)
		(local $ptr i32)

		;; ensure max memory > next pointer, -23 address alignment exception
		(call $__assert
			(i32.gt_u
				(global.get $SIZEOF_MEMORY_MAX)
				(local.tee $nxt
					(i32.add
						(call $__alloc_align (local.get $size))
						(local.tee $ptr
							(call $__alloc_align (i32.load (global.get $PTR_ALLOC)))))))
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
