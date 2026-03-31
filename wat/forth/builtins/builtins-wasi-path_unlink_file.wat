	(func $__forth_fn_wasi_path_unlink_file (type $TypeForthFn)
		(local $path_len i32)
		(local $path_ptr i32)

		(local.set $path_len (call $__stack_dat_pop))
		(local.set $path_ptr (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__wasi::path_unlink_file
				(call $__stack_dat_pop) ;; dir_fd
				(local.get $path_ptr)
				(local.get $path_len)))
	)
