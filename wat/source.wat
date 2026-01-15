
(;

	source.wat

	Sources are wrappers around in-memory code or files. These are
	managed with a stck-based apparch (extending stack) to allow for
	sources to include others.

;)

	;; unified structure for sources
	;;
	;; 		f/m  0: kind - memory or file
	;; 		f/m  4: ptr - pointer to file definition or full code (for memory)
	;; 		  m  8: len - length of the full code
	;; 		f/m 12: row - current source row
	;; 		f/m 16: ln_iov - pointer to line buffer
	;; 		f/m 20: ln_off - offset in the line buffer
	;; 		f   24: in_iov - pointer to file read buffer
	;; 		f   28: in_off - offset in the file read buffer
	;; 		f   32: is_eof - eof reached
	;; 		f   36: pd - path descriptor
	;; 		f   40: fd - file descriptor
	(global $SRC_KIND_MEM   i32 (i32.const 0))
	(global $SRC_KIND_FIL   i32 (i32.const 1))
	(global $IDX_SRC_KIND   i32 (i32.const 0))
	(global $IDX_SRC_PTR    i32 (i32.const 4))
	(global $IDX_SRC_LEN    i32 (i32.const 8))
	(global $IDX_SRC_ROW    i32 (i32.const 12))
	(global $IDX_SRC_LN_IOV i32 (i32.const 16))
	(global $IDX_SRC_LN_OFF i32 (i32.const 20))
	(global $IDX_SRC_IN_IOV i32 (i32.const 24))
	(global $IDX_SRC_IN_OFF i32 (i32.const 28))
	(global $IDX_SRC_IS_EOF i32 (i32.const 32))
	(global $IDX_SRC_PD     i32 (i32.const 36))
	(global $IDX_SRC_FD     i32 (i32.const 40))
	(global $SIZEOF_SRC     i32 (i32.const 44))
	(global $SIZEOF_SRC_IN  i32 (i32.const 256)) ;; file read buffer size
	(global $SIZEOF_SRC_LN  i32 (i32.const 1024)) ;; line buffer size

	;;
	;; Restores overall state from a source buffer
	;;
	(func $__src_restore (param $s i32)
		;; PTR_SRC_ID = frame ptr (or 0)
		(i32.store (global.get $PTR_SRC_ID) (local.get $s))

		;; clear global state (to be set in refill)
		(call $__line_clear)

		;; s == 0 => clear parse state
		(local.get $s) (if

			;; we have a valid source
			(then
				;; parse_iov_ptr from frame
				(global.set $parse_iov_ptr (call $__src_get_ln_iov (local.get $s)))
				(global.set $parse_code_row (call $__src_get_row (local.get $s)))

				;; kind?
				(call $__src_get_kind (local.get $s)) (if

					;; file
					(then
						(global.set $parse_code_idx (call $__src_get_ln_off (local.get $s)))
						(global.set $parse_code_ptr (i32.const 0))
						(global.set $parse_code_len (i32.const 0)))

					;; memory
					(else
						(global.set $parse_code_idx (call $__src_get_in_off (local.get $s)))
						(global.set $parse_code_ptr (call $__src_get_ptr (local.get $s)))
    					(global.set $parse_code_len (call $__src_get_len (local.get $s))))))

			;; zero source, clear all
			(else
				(global.set $parse_iov_ptr  (i32.const 0))
				(global.set $parse_code_ptr (i32.const 0))
				(global.set $parse_code_len (i32.const 0))
				(global.set $parse_code_idx (i32.const 0))
				(global.set $parse_code_row (i32.const 0))))
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
		(local $fd i32)
		(local $pd i32)

		;; kind?
		(call $__src_get_kind (local.get $s)) (if

			;; file, open it
			(then
				;; open the file
				(call $__file_open
					(call $__iov_get_str_len
						(call $__src_get_ptr (local.get $s))))
				local.set $fd
				local.set $pd

				;; store path & file descriptors
				(call $__src_set_fd (local.get $s) (local.get $fd))
				(call $__src_set_pd (local.get $s) (local.get $pd)))

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

	(func $__src_get_len (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_LEN))))

	(func $__src_set_len (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_LEN)) (local.get $v)))

	(func $__src_get_in_iov (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_IN_IOV))))

	(func $__src_set_in_iov (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_IN_IOV)) (local.get $v)))

	(func $__src_get_in_off (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_IN_OFF))))

	(func $__src_set_in_off (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_IN_OFF)) (local.get $v)))

	(func $__src_get_ln_iov (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_LN_IOV))))

	(func $__src_set_ln_iov (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_LN_IOV)) (local.get $v)))

	(func $__src_get_ln_off_ptr (param $s i32) (result i32)
		(i32.add (local.get $s) (global.get $IDX_SRC_LN_OFF)))

	(func $__src_get_ln_off (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_LN_OFF))))

	(func $__src_set_ln_off (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_LN_OFF)) (local.get $v)))

	(func $__src_get_ptr (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_PTR))))

	(func $__src_set_ptr (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_PTR)) (local.get $v)))

	(func $__src_get_row (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_ROW))))

	(func $__src_set_row (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_ROW)) (local.get $v)))

	(func $__src_get_fd (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_FD))))

	(func $__src_set_fd (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_FD)) (local.get $v)))

	(func $__src_get_pd (param $s i32) (result i32)
		(i32.load (i32.add (local.get $s) (global.get $IDX_SRC_PD))))

	(func $__src_set_pd (param $s i32) (param $v i32)
		(i32.store (i32.add (local.get $s) (global.get $IDX_SRC_PD)) (local.get $v)))

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
