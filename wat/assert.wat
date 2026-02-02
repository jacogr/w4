
(;

	assert.wat

	Assertion routines, as both used inside the codebase to ensure
	conditions and as a underlying base for throw. (To be expanded)

;)

	;;
	;; Emits an error when val == 0, otherwise returns with no action taken.
	;;
	;; Codes are from the standard:
	;; https://forth-standard.org/standard/exception
	;;
	(func $__assert (param $val i32) (param $err_code i32)
		(local $err_str i32)
		(local $s i32)
		(local $line_iov i32)
		(local $line_off i32)
		(local $line_fil i32)
		(local $sid i32)
		(local $n i32)

		;; check flag
		(local.get $val) (if

			;; valid, return, nothing to do
			(then return)

			;; zero check, throw error below
			(else))

		;; restore decimal
		(i32.store (global.get $PTR_BASE) (i32.const 10))

		;; avilable frame?
		(local.tee $s (call $__src_frame_peek)) (if

			;; valid frame
			(then
				(local.set $line_iov (call $__src_get_ln_iov (local.get $s)))
				(local.set $line_off (call $__src_get_ln_off (local.get $s)))

				;; frame?
				(call $__src_get_kind (local.get $s)) (if

					;; file, extract name
					(then (local.set $line_fil (call $__src_get_ptr (local.get $s))))

					;; memory, ignore
					(else))

				;; line available?
				(local.get $line_iov) (if

					;; line available, emit it
					(then
						(call $__iov_emit_chr_stderr (i32.const 10)) ;; \n
						(call $__iov_emit_stderr (local.get $line_iov)))

					;; no line, ignore
					(else)))

			;; no frame, ignore
			(else))

		;; error code
		(call $__iov_emit_chr_stderr (i32.const 10)) ;; \n
		(call $__iov_emit_num_stderr (local.get $err_code))
		(call $__iov_emit_chr_stderr (i32.const 32)) ;; ' '

		;; lookup code
		(local.tee $err_str (call $__excep_lookup (local.get $err_code))) (if

			;; have an error string, emit it
			(then
				(call $__iov_emit_str_stderr
					(local.get $err_str)
					(call $__strlen_z (local.get $err_str)))
				(call $__iov_emit_chr_stderr (i32.const 10)))

			;; no string found, skip it
			(else))

		;; (file) row:col and current token
		(local.get $line_fil) (if

			;; have name, emit it
			(then
				(call $__iov_emit_stderr (local.get $line_fil))
				(call $__iov_emit_chr_stderr (i32.const 32)))

			;; no file, skip
			(else))

		(call $__iov_emit_num_stderr (global.get $parse_code_row))
		(call $__iov_emit_chr_stderr (i32.const 58)) ;; ':'
		(call $__iov_emit_num_stderr (local.get $line_off))

		;; current token (still valid if xt_exec is maintained)
		(call $__iov_emit_chr_stderr (i32.const 32)) ;; ' '
		(call $__iov_emit_stderr (global.get $xt_exec))
		(call $__iov_emit_chr_stderr (i32.const 32))

		;; unknown word marker?
		(i32.eq (local.get $err_code) (i32.const -13)) (if

			;; yes, emit additional ? = 63
			(then (call $__iov_emit_chr_stderr (i32.const 63)))

			;; other error, ignore
			(else))

		;; eol
		(call $__iov_emit_chr_stderr (i32.const 10)) ;; \n

		;; include stack (needs to be >1, current displayed above)
		(i32.gt_s (local.tee $n (i32.sub (call $__src_frame_count) (i32.const 1))) (i32.const 1)) (if

			;; we have additional frames
			(then
				;; loop through frames
				(block $done (loop $loop

					;; f = stack_file[i]  (src_frame pointer)
					(local.set $s
						(call $__stack_peek_at
							(i32.const 0)
							(global.get $stack_src)
							(local.get $n)))

					;; file?
					(call $__src_get_kind (local.get $s)) (if

						;; file, emit name row:col
						(then
							(call $__iov_emit_stderr (call $__src_get_ptr (local.get $s)))
							(call $__iov_emit_chr_stderr (i32.const 32))
							(call $__iov_emit_num_stderr (call $__src_get_row (local.get $s)))
							(call $__iov_emit_chr_stderr (i32.const 58)) ;; ':'
							(call $__iov_emit_num_stderr (call $__src_get_in_off (local.get $s)))
							(call $__iov_emit_chr_stderr (i32.const 10)))

						;; memory, skip
						(else))

					;; continue if more
					(br_if $loop
						(i32.ne
							(local.tee $n (i32.sub (local.get $n) (i32.const 1)))
							(i32.const 0))))))

			;; no other frames
			(else))

	m4_ifdef(`DEBUG', `
		;; DEBUG, output stacks
		(call $__DEBUG_emit_stack (i32.load (global.get $PTR_PTR_STACK_DAT)))
		(call $__DEBUG_emit_stack (i32.load (global.get $PTR_PTR_STACK_RET)))
		(call $__DEBUG_emit_stack (i32.load (global.get $PTR_PTR_STACK_CTL)))
	')

		;; TODO proper exception, pass up code on exception stack?
		unreachable
	)

	;;
	;; Ensures that the address is in a known space
	;;
	(func $__assert_ptr (param $ptr i32)
		;; check address, -9 invalid memory address
		(call $__assert
			(i32.and
				;; less than maxiumum allowed
				(i32.le_u (local.get $ptr) (global.get $SIZEOF_MEMORY_MAX))
				(i32.or
					;; in embedded source space
					(i32.ge_u (local.get $ptr) (global.get $W4_FORTH_START))
					;; in allocated space
					(i32.le_u (local.get $ptr) (i32.load (global.get $PTR_ALLOC)))))
			(i32.const -9))
	)
