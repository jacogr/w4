	(func $__forth_fn_wasi_fd_filestat_set_size (type $TypeForthFn)
		(local $size_hi i64)
		(local $size_lo i64)

		(local.set $size_hi (i64.extend_i32_u (call $__stack_dat_pop)))
		(local.set $size_lo (i64.extend_i32_u (call $__stack_dat_pop)))

		(call $__stack_dat_push
			(call $__wasi::fd_filestat_set_size
				(call $__stack_dat_pop) ;; fd
				(i64.or
					(local.get $size_lo)
					(i64.shl (local.get $size_hi) (i64.const 32)))))
	)
