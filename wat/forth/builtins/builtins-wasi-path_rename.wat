	(func $__forth_fn_wasi_path_rename (type $TypeForthFn)
		(local $new_len i32)
		(local $new_ptr i32)
		(local $new_dir_fd i32)
		(local $old_len i32)
		(local $old_ptr i32)

		(local.set $new_len (call $__stack_dat_pop))
		(local.set $new_ptr (call $__stack_dat_pop))
		(local.set $new_dir_fd (call $__stack_dat_pop))
		(local.set $old_len (call $__stack_dat_pop))
		(local.set $old_ptr (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__wasi::path_rename
				(call $__stack_dat_pop) ;; old_dir_fd
				(local.get $old_ptr)
				(local.get $old_len)
				(local.get $new_dir_fd)
				(local.get $new_ptr)
				(local.get $new_len)))
	)
