
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

		;; current frame?
		(call $__src_get_kind (local.tee $s (call $__src_frame_peek))) (if (result i32)

			;; file
			(then (call $__file_read_line (local.get $s)))

			;; memory
			(else (i32.const 0)))

		;; shared tail
		(if (result i32)

			;; success
			(then
				;; row++, SOURCE + >IN
				(call $__src_inc_row (local.get $s))
				(call $__line_set (local.get $s))

				;; success, we have a line
				(i32.const 1))

			;; failure
			(else (i32.const 0)))
	)
