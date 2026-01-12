
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
		(local $len i32)
		(local $idx_curr i32)
		(local $idx_find i32)

		;; reset >IN and SOURCE
		(call $__line_clear)

		;; current frame?
		(local.tee $s (i32.load (global.get $PTR_SRC_ID))) (if

			;; have a frame, continue below
			(then)

			;; no source frame, exit
			(else (return (i32.const 0))))

		;; kind?
		(call $__src_get_kind (local.get $s)) (if (result i32)

			;; file
			(then
				;; do we have refill data?
				(call $__file_read_line (local.get $s)) (if (result i32)

					;; have data, add it
					(then
						;; new row
						(call $__src_set_row
							(local.get $s)
							(i32.add
								(call $__src_get_row (local.get $s))
								(i32.const 1)))
						(global.set $parse_code_row (call $__src_get_row (local.get $s)))

						;; SOURCE = file line iov, >IN-ptr =
						(call $__line_set
							(call $__src_get_ln_iov (local.get $s))
							(call $__src_get_ln_off_ptr (local.get $s)))

						;; parse_iov_ptr already points at line iov via frame
						(i32.const 1))

					;; no data available
					(else (i32.const 0))))

			;; memory
			(else
				;; start
				(local.set $idx_find (global.get $parse_code_idx))

				;; loop until eol
				(block $exit (loop $loop

					;; break is we are at eof
					(br_if $exit
						(i32.or
							(i32.eqz (global.get $parse_code_ptr))
							(i32.eq (global.get $parse_code_idx) (global.get $parse_code_len))))

					;; eol?
					(call $__ch_is_eol
						(i32.load8_u
							(i32.add (global.get $parse_code_ptr) (global.get $parse_code_idx))))

					;; increment column
					(global.set $parse_code_idx (i32.add (global.get $parse_code_idx) (i32.const 1)))

					;; continue if not eol
					i32.eqz (br_if $loop)))

				;; movement?
				(i32.ne
					(local.tee $idx_curr (global.get $parse_code_idx))
					(local.get $idx_find)) (if

					;; yes, new position update
					(then
						;; row++
						(global.set $parse_code_row
							(i32.add (global.get $parse_code_row) (i32.const 1)))
						(call $__src_set_row
							(local.get $s)
							(global.get $parse_code_row))

						;; persist idx back into frame
						(call $__src_set_ln_off
							(local.get $s)
							(global.get $parse_code_idx))

						;; SOURCE slice
						(call $__line_set
							(call $__iov_fill
								(global.get $parse_iov_ptr)
								(i32.add (global.get $parse_code_ptr) (local.get $idx_find))
								(local.tee $len (i32.sub (local.get $idx_curr) (local.get $idx_find)))
								(i32.const 0))
							(call $__src_get_ln_off_ptr (local.get $s))))

					;; no movement, exit below
					(else))

				;; 1=success if we have length
				(i32.ne (local.get $len) (i32.const 0))))
	)

	;;
	;; Ensure that a file is only included once
	;;
	;; https://forth-standard.org/standard/file/REQUIRED
	;;
	(func $__internal_required (param $str i32) (param $len i32)
		(call $__internal_included_inner (local.get $str) (local.get $len) (i32.const 1))
	)

	;;
	;; Includes a file into the source, suspends/resumes buffer parsing
	;; (Not in the standards docs, but widely used)
	;;
	;; https://forth-standard.org/standard/file/INCLUDED
	;;
	(func $__internal_included (export "evaluate_file") (param $str i32) (param $len i32)
		(call $__internal_included_inner
			(local.get $str)
			(local.get $len)
			(i32.const 0))
	)

	(func $__internal_included_inner (param $str i32) (param $len i32) (param $is_req i32)
		(local $f i32)
		(local $s i32)
		(local $p i32)
		(local $hash i32)
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
							(call $__iov_get_str_len
								(call $__src_get_ptr (local.get $p)))
							(local.get $str)
							(local.get $len))
						local.set $len
						local.set $str)

					;; memory, skip
					(else)))

			;; none, no adjustments
			(else))

		;; create hash on adjusted values
		(local.set $hash (call $__hash (local.get $str) (local.get $len)))

		;; duplicate check?
		(local.get $is_req) (if

			;; check dupes
			(then
				;; included?
				(call $__lookup_find
					(global.get $list_incl)
					(local.get $str)
					(local.get $len)
					(local.get $hash)) (if

					;; already included, return
					(then return)

					;; not included, continue
					(else)))

			;; no checking
			(else))

		;; add to the known includes (w/ non-transient string)
		(call $__lookup_append
			(global.get $list_incl)
			(local.get $hash)
			(local.tee $f
				(call $__val_new
					(call $__strdup_n (local.get $str) (local.get $len))
					(local.get $len)
					(local.get $hash)
					(local.tee $s (call $__alloc (global.get $SIZEOF_SRC)))
					(global.get $FLG_VISIBLE))))

		;; store base info
		(call $__src_set_kind (local.get $s) (global.get $SRC_KIND_FIL))
		(call $__src_set_ptr (local.get $s) (local.get $f))

		;; create iovs for input & line
		(call $__src_set_in_iov
			(local.get $s)
			(call $__iov_fill
				(call $__alloc (global.get $SIZEOF_IOV))
				(call $__alloc (global.get $SIZEOF_SRC_IN))
				(i32.const 0)
				(i32.const 0)))
		(call $__src_set_ln_iov
			(local.get $s)
			(call $__iov_fill
				(call $__alloc (global.get $SIZEOF_IOV))
				(call $__alloc (global.get $SIZEOF_SRC_LN))
				(i32.const 0)
				(i32.const 0)))

		;; add and evaluate
		(call $__internal_evaluate_frame (local.get $s))
	)
