
(;

	source.wat

	Sources are wrappers around in-memory code or files. These are
	managed with a stck-based apparch (extending stack) to allow for
	sources to include others.

;)

	;; unified structure for sources
	;;
	;; 		f/m  0: ptr - pointer to file path or full code (for memory)
	;; 		f/m  4: len - length of the path or full code
	;;		f    8: hash - hash of the filename (lookup)
	;; 		f/m 12: flags - memory (= 0) or file
	;; 		f   16: fd - file descriptor
	;; 		f/m 20: row - current source row
	;; 		f/m 24: ln_ptr - pointer to line buffer
	;; 		f/m 28: ln_len - length of line buffer data
	;; 		f/m 32: ln_pos - offset in the line buffer
	;; 		f   36: in_ptr - pointer to file read buffer
	;; 		f   40: in_len - length of read buffer data
	;; 		f   44: in_pos - offset in the file read buffer
	;; 		f   48: is_eof - eof reached
	(global $IDX_SRC_PTR    i32 (i32.const 0))  ;; 0, iov
	(global $IDX_SRC_LEN    i32 (i32.const 4))  ;; 1, iov
	(global $IDX_SRC_HASH   i32 (i32.const 8))  ;; 2, iov
	(global $IDX_SRC_KIND   i32 (i32.const 12)) ;; 3, flags
	(global $IDX_SRC_FD     i32 (i32.const 16)) ;; 4
	(global $IDX_SRC_ROW    i32 (i32.const 20)) ;; 5
	(global $IDX_SRC_LN_PTR i32 (i32.const 24)) ;; 6
	(global $IDX_SRC_LN_LEN i32 (i32.const 28)) ;; 7
	(global $IDX_SRC_LN_POS i32 (i32.const 32)) ;; 8
	(global $IDX_SRC_IN_PTR i32 (i32.const 36)) ;; 9
	(global $IDX_SRC_IN_LEN i32 (i32.const 40)) ;; a
	(global $IDX_SRC_IN_POS i32 (i32.const 44)) ;; b
	(global $IDX_SRC_IS_EOF i32 (i32.const 48)) ;; c
	(global $SIZEOF_SRC     i32 (i32.const 52))
	(global $SIZEOF_SRC_IN  i32 (i32.const 256)) ;; file read buffer size
	(global $SIZEOF_SRC_LN  i32 (i32.const 1024)) ;; line buffer size

	;;
	;; Restores overall state from a source buffer
	;;
	(func $__src_restore (param $s i32)
		;; clear global state (to be set in refill)
		(call $__line_clear)

		;; set current frame
		(global.set $parse_frame (local.get $s))

		;; s == 0 => clear parse state
		(local.get $s) (if

			;; we have a valid source
			(then
				;; kind?
				(call $__src_get_kind (local.get $s)) (if

					;; file
					(then
						;; PTR_SRC_ID = frame ptr (or 0)
						(i32.store (global.get $PTR_SRC_ID) (local.get $s)))

					;; memory
					(else
						;; PTR_SRC_ID = -1
						(i32.store (global.get $PTR_SRC_ID) (i32.const -1)))))

			;; zero source, clear all
			(else
				;; PTR_SRC_ID = 0
				(i32.store (global.get $PTR_SRC_ID) (i32.const 0))))
	)

	;;
	;; Frame count, aka stack size
	;;
	(func $__src_frame_count (result i32)
		(i32.load (global.get $stack_src))
	)

	;;
	;; Peek at the top stack frame
	;;
	(func $__src_frame_peek (result i32)
		(call $__src_frame_count) (if (result i32)

			;; retrieve top
			(then (call $__stack_peek (i32.const 0) (global.get $stack_src)))

			;; 0 = “no frame”
			(else (i32.const 0)))
	)

	;;
	;; Push a frame to the stack
	;;
	(func $__src_push_frame (param $s i32)
		;; kind?
		(call $__src_get_kind (local.get $s)) (if

			;; file, open it
			(then
				;; store file descriptor
				(call $__src_set_fd
					(local.get $s)
					(call $__file_open
						(call $__iov_get_str_len (local.get $s)))))

			;; memory, nothing to do
			(else))

		;; store it on the stack, closed on pop
		(call $__stack_push (i32.const 0) (global.get $stack_src) (local.get $s))
		(call $__src_restore (local.get $s))
	)

	;;
	;; Remove a frame from the stack, close all associated descriptors
	;;
	(func $__src_pop_frame
		(local $fd i32)
		(local $s i32)

		;; valid source?
		(local.tee $s (call $__stack_pop (i32.const 0) (global.get $stack_src))) (if

			;; we have a source
			(then
				;; kind?
				(call $__src_get_kind (local.get $s)) (if

					;; file, close it
					(then
						;; not stdin/stdout/stderr?
						(i32.gt_u
							(local.tee $fd (call $__src_get_fd (local.get $s)))
							(i32.const 2)) (if

							;; iov in-range
							(then
								;; close it, ignore error, we are done
								(drop (call $__wasi::fd_close (local.get $fd)))

								;; prevent double-close if unwound twice
								(call $__src_set_fd (local.get $s) (i32.const 0)))

							;; std* fd
							(else)))

					;; memory, ignore
					(else)))

				;; no source
				(else))

		;; start with the next frame
		(call $__src_restore (call $__src_frame_peek))
	)

	;;
	;; Helpers for the source structure
	;;

	(func $__src_get_is_eof (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_IS_EOF))))

	(func $__src_set_is_eof (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_IS_EOF)) (local.get $v)))

	(func $__src_get_kind (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_KIND))))

	(func $__src_set_kind (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_KIND)) (local.get $v)))

	(func $__src_get_in_iov (param $s i32) (result i32)
		(i32.add (local.get $s) (global.get $IDX_SRC_IN_PTR)))

	(func $__src_get_in_ptr (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_IN_PTR))))

	(func $__src_set_in_ptr (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_IN_PTR)) (local.get $v)))

	(func $__src_get_in_len (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_IN_LEN))))

	(func $__src_set_in_len (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_IN_LEN)) (local.get $v)))

	(func $__src_get_in_off (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_IN_POS))))

	(func $__src_set_in_off (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_IN_POS)) (local.get $v)))

	(func $__src_get_ln_iov (param $s i32) (result i32)
		(i32.add (local.get $s) (global.get $IDX_SRC_LN_PTR)))

	(func $__src_get_ln_ptr (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_LN_PTR))))

	(func $__src_set_ln_ptr (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_LN_PTR)) (local.get $v)))

	(func $__src_get_ln_off_ptr (param $s i32) (result i32)
		(i32.add (local.get $s) (global.get $IDX_SRC_LN_POS)))

	(func $__src_get_ln_off (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_LN_POS))))

	(func $__src_set_ln_off (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_LN_POS)) (local.get $v)))

	(func $__src_get_row (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_ROW))))

	(func $__src_set_row (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_ROW)) (local.get $v)))

	(func $__src_inc_row (param $s i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_ROW)) (i32.add (i32.const 1) (call $__src_get_row (local.get $s)))))

	(func $__src_get_fd (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_FD))))

	(func $__src_set_fd (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_FD)) (local.get $v)))

	;;
	;; Helpers for PTR_PTR_LINE_OFF = >IN and PTR_LINE_IOV = SOURCE
	;;

	(func $__line_clear
		(call $__line_set_off_ptr__ (i32.const 0))
		(call $__line_set_iov__ (i32.const 0))
	)

	(func $__line_set (param $iov i32) (param $off_ptr i32)
		(call $__line_set_off_ptr__ (local.get $off_ptr))
		(call $__line_set_iov__ (local.get $iov))
	)

	(func $__line_set_off (param $v i32)
		(local $ptr i32)

		;; valid offset ptr
		(call $__assert_ptr (local.tee $ptr (call $__line_get_off_ptr__)))

		;; store
		(i32.store (local.get $ptr) (local.get $v)))

	(func $__line_get_off (result i32)
		(i32.load (call $__line_get_off_ptr__)))

	(func $__line_get_iov (result i32)
		(i32.load (global.get $PTR_LINE_IOV)))

	;;
	;; Never accessed out of this location
	;;

	(func $__line_get_off_ptr__ (result i32)
		(i32.load (global.get $PTR_PTR_LINE_OFF)))

	(func $__line_set_off_ptr__ (param $v i32)
		(i32.store (global.get $PTR_PTR_LINE_OFF) (local.get $v)))

	(func $__line_set_iov__ (param $v i32)
		(i32.store (global.get $PTR_LINE_IOV) (local.get $v)))
