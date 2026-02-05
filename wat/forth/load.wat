
(;

	forth/load.wat

	Provides handling of various sources, either from file or memory,
	interacting with the source.wat structures. Here we handle refill
	from sources (once a line is exhausted)
;)

	;;
	;; Refills the source buffer with the next line
	;;
	;; https://forth-standard.org/standard/core/REFILL
	;;
	(func $__internal_refill (result i32)
		(local $s i32)

		;; reset >IN and SOURCE
		(call $__line_clear)

		;; current frame?
		(local.tee $s (call $__src_frame_peek)) (if

			;; have a frame, continue below
			(then)

			;; no source frame, exit
			(else (return (i32.const 0))))

		;; read next line (file/mem), returns success flag
		(call $__src_get_kind (local.get $s)) (if (result i32)

			;; file
			(then (call $__file_read_line (local.get $s)))

			;; memory
			(else (call $__mem_read_line (local.get $s))))

		;; shared tail
		(if (result i32)

			;; success
			(then
				;; row++
				(call $__src_inc_row (local.get $s))

				;; SOURCE + >IN
				(call $__line_set
					(call $__src_get_ln_iov (local.get $s))
					(call $__src_get_ln_off_ptr (local.get $s)))

				;; success, we have a line
				(i32.const 1))

			;; failure
			(else (i32.const 0)))
	)
