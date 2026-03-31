	(func $__forth_fn_wasi_fd_filestat_get (type $TypeForthFn)
		(call $__stack_dat_push
			(call $__wasi::fd_filestat_get
				(call $__stack_dat_pop) ;; fd
				(call $__stack_dat_pop))) ;; filestat_ptr
	)
