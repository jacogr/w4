	(func $__forth_fn_wasi_fd_write (type $TypeForthFn)
		(local $iovs i32)
		(local $iovs_len i32)
		(local $n_ptr i32)

		(local.set $n_ptr (call $__stack_dat_pop))
		(local.set $iovs_len (call $__stack_dat_pop))
		(local.set $iovs (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__wasi::fd_write
				(call $__stack_dat_pop) ;; fd
				(local.get $iovs)
				(local.get $iovs_len)
				(local.get $n_ptr)))
	)
