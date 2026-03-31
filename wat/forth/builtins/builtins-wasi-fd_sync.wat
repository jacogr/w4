	(func $__forth_fn_wasi_fd_sync (type $TypeForthFn)
		(call $__stack_dat_push
			(call $__wasi::fd_sync
				(call $__stack_dat_pop))) ;; fd
	)
