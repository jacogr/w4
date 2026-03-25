	(func $__forth_fn_wasi_fd_close (type $TypeForthFn)
		(call $__stack_dat_push
			(call $__wasi::fd_close
				(call $__stack_dat_pop))) ;; fd
	)
