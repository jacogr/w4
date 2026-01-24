
(;

	debug.wat

	DEBUG routines, added with make DEBUG=1.

	NOTE: These are not pretty, they are functional. They are most-probably
	not commented to the same standard as the rest of the codebase, not are
	they as clean as the normal codebase in terms of structure.

;)

	(func $__DEBUG_emit_num (param $num i32) (param $base i32)
		;; setup the iov and print it
		(call $__iov_emit_stdout
			(call $__iov_fill
				(global.get $PTR_PRI_EMIT_STR)
				(call $__num_to_str
					(local.get $base)
					(local.get $num)
					(i32.const 0))
				(i32.const 0)))
	)

	(func $__DEBUG_emit_stack (param $ptr i32)
		(local $len i32)
		(local $cont i32)
		(local $tokn i32)
		(local $list i32)
		(local $ownr i32)
		(local $here i32)

		(call $__DEBUG_emit_num (local.get $ptr) (i32.const 16))
		(call $__iov_emit_chr_stdout (i32.const 9))
		(call $__DEBUG_emit_num (local.tee $len (i32.load (local.get $ptr))) (i32.const 10))
		(call $__iov_emit_chr_stdout (i32.const 10))

		(block $exit (loop $loop
			(br_if $exit
				(i32.eqz (local.get $len)))

			(call $__DEBUG_emit_num (local.tee $ptr (i32.add (local.get $ptr) (i32.const 4))) (i32.const 16))
			(call $__iov_emit_chr_stdout (i32.const 9))

			;; content
			(call $__DEBUG_emit_num (local.tee $cont (i32.load (local.get $ptr))) (i32.const 16))

			;; display all headers (return + control)
			(i32.and
				(i32.ne
					(local.get $cont)
					(i32.const 0))
				(i32.lt_u
					(local.get $cont)
					(local.tee $here (i32.load (global.get $PTR_ALLOC))))) (if

				;; within pointer range
				(then
					(i32.and
						(i32.ne
							(local.tee $tokn (call $__val_get_value (local.get $cont)))
							(i32.const 0))
						(i32.lt_u
							(local.get $tokn)
							(local.get $here))) (if

						;; xt within memory range
						(then
							(i32.and
								(i32.and
									(i32.ne (call $__iov_get_str (local.get $tokn)) (i32.const 0))
									(i32.lt_u (call $__iov_get_len (local.get $tokn)) (i32.const 32)))
								(call $__has_flag
									(call $__val_get_flags (local.get $tokn))
									(global.get $FLG_ANY))) (if

								;; has flags & string
								(then
									(call $__iov_emit_chr_stdout (i32.const 9))
									(call $__iov_emit_stdout (local.get $tokn))

									(i32.lt_u
										(local.tee $list (call $__ent_get_link (local.get $cont)))
										(local.get $here)) (if

										;; seems like a list
										(then
											(i32.lt_u
												(local.tee $ownr (call $__list_get_owner (local.get $list)))
												(local.get $here)) (if

											;; owner within memory range
											(then
												(i32.and
													(i32.and
														(i32.ne (call $__iov_get_str (local.get $ownr)) (i32.const 0))
														(i32.lt_u (call $__iov_get_len (local.get $ownr)) (i32.const 32)))
													(call $__has_flag
														(call $__val_get_flags (local.get $ownr))
														(global.get $FLG_TKN))) (if

													;; has flags and string
													(then
															(call $__iov_emit_chr_stdout (i32.const 32))
															(call $__iov_emit_chr_stdout (i32.const 126)) ;; ~
															(call $__iov_emit_chr_stdout (i32.const 32))
															(call $__iov_emit_stdout (local.get $ownr))))))))))))))

			;; move to next
			(call $__iov_emit_chr_stdout (i32.const 10))
			(local.set $len (i32.sub (local.get $len) (i32.const 1)))

			;; continue
			(br $loop)))
	)

	(func $__DEBUG_emit_dict
		(call $__iov_emit_chr_stdout (i32.const 10))
		(call $__iov_emit_chr_stdout (i32.const 10))
		(call $__DEBUG_emit_list (i32.load (global.get $PTR_PTR_WID_CURR)))
	)

	(func $__DEBUG_emit_list (param $ptr_list i32)
		(local $ptr_ent i32)
		(local $ptr_xt i32)

		;; print the list from ptr position
		(block $exit

			;; break if we have a zero pointer
			(br_if $exit
				(i32.eqz (local.get $ptr_list)))

			(call $__DEBUG_emit_num (local.get $ptr_list) (i32.const 16))
			(call $__iov_emit_chr_stdout (i32.const 10))

			(local.set $ptr_ent (call $__list_get_head (local.get $ptr_list)))

			(loop $loop

				;; exit on empty header
				(br_if $exit
					(i32.eqz (local.get $ptr_ent)))

				;; hdr address
				(call $__DEBUG_emit_num
					(local.get $ptr_ent)
					(i32.const 16))
				(call $__iov_emit_chr_stdout (i32.const 9))

				;; get the xt
				(local.tee $ptr_xt (call $__val_get_value (local.get $ptr_ent)))

				;; ;; print hash
				;; (call $__iov_emit_chr_stdout (i32.const 9))
				;; (call $__DEBUG_emit_num (i32.load (i32.add (local.get $ptr_xt) (i32.const 0x8))) (i32.const 16))
				;; (call $__iov_emit_chr_stdout (i32.const 9))

				(call $__DEBUG_emit_num
					(local.get $ptr_xt)
					(i32.const 16))
				(call $__iov_emit_chr_stdout (i32.const 9))

				;; flags
				(call $__DEBUG_emit_num (call $__val_get_flags (local.get $ptr_xt)) (i32.const 16))
				(call $__iov_emit_chr_stdout (i32.const 9))

				;; value
				(call $__DEBUG_emit_num (call $__val_get_value (local.get $ptr_xt)) (i32.const 16))
				(call $__iov_emit_chr_stdout (i32.const 9))

				;; text
				(call $__iov_emit_stdout (local.get $ptr_xt))
				(call $__iov_emit_chr_stdout (i32.const 10))

				;; advance to next
				(local.set $ptr_ent (call $__ent_get_next (local.get $ptr_ent)))

				br $loop))

		(call $__iov_emit_chr_stdout (i32.const 10))
	)
