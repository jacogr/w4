	(func $__forth_fn_wasi_fd_seek (type $TypeForthFn)
		(local $new_ptr i32)
		(local $whence i32)
		(local $off_hi i64)
		(local $off_lo i64)

		(local.set $new_ptr (call $__stack_dat_pop))
		(local.set $whence (call $__stack_dat_pop))
		(local.set $off_hi (i64.extend_i32_u (call $__stack_dat_pop)))
		(local.set $off_lo (i64.extend_i32_u (call $__stack_dat_pop)))

		(call $__stack_dat_push
			(call $__wasi::fd_seek
				(call $__stack_dat_pop) ;; fd
				(i64.or
					(local.get $off_lo)
					(i64.shl (local.get $off_hi) (i64.const 32)))
				(local.get $whence)
				(local.get $new_ptr)))
	)
