	(func $__forth_fn_wasi_fd_tell (type $TypeForthFn)
		(call $__stack_dat_push
			(call $__wasi::fd_tell
				(call $__stack_dat_pop) ;; fd
				(call $__stack_dat_pop))) ;; offset_ptr
	)
