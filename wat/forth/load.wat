
(;

	forth/load.wat

	Provides handling of various sources, either from file or memory,
	interacting with the source.wat structures. Here we handle refill
	from sources (once a line is exhausted) as well as creating a new
	source, e.g. via include/required

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

	;;
	;; Includes a file into the source, suspends/resumes buffer parsing
	;; (Not in the standards docs, but widely used)
	;;
	;; https://forth-standard.org/standard/file/INCLUDED
	;;
	(func $__internal_included (export "evaluate_file") (param $str i32) (param $len i32)
		(local $f i32)
		(local $s i32)
		(local $p i32)
		(local $rel_str i32)
		(local $rel_len i32)

		;; zero name, -16 attempt to use zero-length string as a name
		(call $__assert (local.get $len) (i32.const -16))

		;; is there a previous frame?
		(local.tee $p (call $__src_frame_peek)) (if

			;; previous
			(then
				;; file?
				(call $__src_get_kind (local.get $p)) (if

					;; file
					(then
						;; create relative
						(call $__file_relative
							(call $__iov_get_str_len (local.get $p))
							(local.get $str)
							(local.get $len))
						local.set $len
						local.set $str)

					;; memory, skip
					(else)))

			;; none, no adjustments
			(else))

		;; add the file
		(local.set $s
			(call $__sized_val_new
				(global.get $SIZEOF_SRC)
				(call $__strdup_n (local.get $str) (local.get $len))
				(local.get $len)
				(call $__hash (local.get $str) (local.get $len))
				(i32.const 0)
				(global.get $FLG_VISIBLE)))

		;; create iovs for input & line
		(call $__src_set_in_ptr (local.get $s) (call $__alloc (global.get $SIZEOF_SRC_IN)))
		(call $__src_set_ln_ptr (local.get $s) (call $__alloc (global.get $SIZEOF_SRC_LN)))

		;; add and evaluate
		(call $__internal_include_file (local.get $s))
	)
