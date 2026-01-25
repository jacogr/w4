
(;

	iov.wat

	Helpers to work with iov structures, as used as the base for all
	list values as well as io operations from wasi. Since the iov is
	the base of list entries, this also means that entries can use
	these functions directly, i.e. from a list lookup result we can get
	the value and directly emit it.

;)

	;; offsets for items on lists, with memory layout in terms of cells:
	;;
	;;   	 str (i32), len (i32), extra/hash (i32)
	(global $IDX_IOV_STR   i32 (i32.const 0))
	(global $IDX_IOV_LEN   i32 (i32.const 4))
	(global $IDX_IOV_HASH  i32 (i32.const 8))
	(global $SIZEOF_IOV    i32 (i32.const 12))

	;;
	;; Populates an iov header using the supplied string and length
	;;
	(func $__iov_fill (param $ptr i32) (param $str i32) (param $len i32) (param $hash i32) (result i32)
		(call $__iov_set_str_len (local.get $ptr) (local.get $str) (local.get $len))
		(call $__iov_set_hash (local.get $ptr) (local.get $hash))

		;; return pointer
		local.get $ptr
	)

	;;
	;; Outputs the string at a specified iov location to the specified
	;; device, stdout = 1, stderr = 2
	;;
	(func $__iov_emit (param $io i32) (param $ptr i32)
		;; output a single iov to stdout, drop errno
		(drop
			(call $__wasi::fd_write
				(local.get $io) ;; stdout = 1, stderr = 2
				(local.get $ptr)
				(i32.const 1) ;; only a single iov is written
				(global.get $PTR_PRI_EMIT_RES)))
	)

	;;
	;; Outputs a single character
	;;
	(func $__iov_emit_chr (param $io i32) (param $ch i32)
		(local $ch_ptr i32)

		;; store the character in the scratch area
		(i32.store8
			(local.tee $ch_ptr (i32.add (global.get $PTR_PRI_EMIT_STR) (global.get $SIZEOF_IOV)))
			(local.get $ch))

		;; setup the iov and print it
		(call $__iov_emit
			(local.get $io)
			(call $__iov_fill
				(global.get $PTR_PRI_EMIT_STR)
				(local.get $ch_ptr)
				(i32.const 1)
				(i32.const 0)))
	)

	;;
	;; Outputs a string
	;;
	(func $__iov_emit_str (param $io i32) (param $str i32) (param $len i32)
		;; setup the iov and print it
		(call $__iov_emit
			(local.get $io)
			(call $__iov_fill
				(global.get $PTR_PRI_EMIT_STR)
				(local.get $str)
				(local.get $len)
				(i32.const 0)))
	)

	;;
	;; Outputs a number
	;;
	(func $__iov_emit_num (param $io i32) (param $val i32)
		(local $is_neg i32)

		;; create a absolute
		(local.tee $is_neg (i32.lt_s (local.get $val) (i32.const 0))) (if

			;; negative, make positive
			(then (local.set $val (i32.mul (local.get $val) (i32.const -1))))

			;; positive, keep as-is
			(else))

		;; setup the iov and print it
		(call $__iov_emit
			(local.get $io)
			(call $__iov_fill
				(global.get $PTR_PRI_EMIT_STR)
				(call $__num_to_str
					(call $__get_base)
					(local.get $val)
					(local.get $is_neg))
				(i32.const 0)))
	)

	;;
	;; iov emit helpers
	;;

	(func $__iov_emit_stdout (param $ptr i32)
		(call $__iov_emit (i32.const 1) (local.get $ptr)))

	(func $__iov_emit_chr_stdout (param $ch i32)
		(call $__iov_emit_chr (i32.const 1) (local.get $ch)))

	(func $__iov_emit_num_stdout (param $val i32)
		(call $__iov_emit_num (i32.const 1) (local.get $val)))

	(func $__iov_emit_hex_stdout (param $val i32)
		(call $__iov_emit_stdout
				(call $__iov_fill
					(global.get $PTR_PRI_EMIT_STR)
					(call $__num_to_str
						(i32.const 16)
						(local.get $val)
						(i32.const 0))
					(i32.const 0))))

	(func $__iov_emit_str_stdout (param $str i32) (param $len i32)
		(call $__iov_emit_str (i32.const 1) (local.get $str) (local.get $len)))

	(func $__iov_emit_stderr (param $ptr i32)
		(call $__iov_emit (i32.const 2) (local.get $ptr)))

	(func $__iov_emit_chr_stderr (param $ch i32)
		(call $__iov_emit_chr (i32.const 2) (local.get $ch)))

	(func $__iov_emit_num_stderr (param $val i32)
		(call $__iov_emit_num (i32.const 2) (local.get $val)))

	(func $__iov_emit_str_stderr (param $str i32) (param $len i32)
		(call $__iov_emit_str (i32.const 2) (local.get $str) (local.get $len)))

	;;
	;; Helpers for iov structures
	;;

	(func $__iov_get_str (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_IOV_STR))))

	(func $__iov_set_str (param $ptr i32) (param $str i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_IOV_STR)) (local.get $str)))

	(func $__iov_get_len (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_IOV_LEN))))

	(func $__iov_set_len (param $ptr i32) (param $len i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_IOV_LEN)) (local.get $len)))

	(func $__iov_get_hash (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_IOV_HASH))))

	(func $__iov_set_hash (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_IOV_HASH)) (local.get $val)))

	(func $__iov_get_str_len (param $ptr i32) (result i32 i32)
		(call $__iov_get_str (local.get $ptr))
		(call $__iov_get_len (local.get $ptr)))

	(func $__iov_set_str_len (param $ptr i32) (param $str i32) (param $len i32)
		(call $__iov_set_str (local.get $ptr) (local.get $str))
		(call $__iov_set_len (local.get $ptr) (local.get $len)))
