	(func $__forth_fn_wasi_path_filestat_get (type $TypeForthFn)
		(local $filestat_ptr i32)
		(local $path_len i32)
		(local $path_ptr i32)
		(local $flags i32)

		(local.set $filestat_ptr (call $__stack_dat_pop))
		(local.set $path_len (call $__stack_dat_pop))
		(local.set $path_ptr (call $__stack_dat_pop))
		(local.set $flags (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__wasi::path_filestat_get
				(call $__stack_dat_pop) ;; dir_fd
				(local.get $flags)
				(local.get $path_ptr)
				(local.get $path_len)
				(local.get $filestat_ptr)))
	)
