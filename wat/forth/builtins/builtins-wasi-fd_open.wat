		(local $opened_fd_ptr i32)
		(local $fdflags i32)
		(local $fs_rights_inheriting i64)
		(local $fs_rights_base i64)
		(local $oflags i32)
		(local $path_len i32)
		(local $path_ptr i32)
		(local $dirflags i32)

		(local.set $opened_fd_ptr (call $__stack_dat_pop))
		(local.set $fdflags (call $__stack_dat_pop))

		;; NOTE we assume (based on the available flags) that we don't
		;; need the high bit flags for usage in our envionement at this point.
		;; This is certainly the case, we only want "simple" reads/writes, not
		;; yet any more exotic stuff. In the future, we may need to change this
		;; interface if the need arrises
		(local.set $fs_rights_inheriting (i64.extend_i32_u (call $__stack_dat_pop)))
		(local.set $fs_rights_base (i64.extend_i32_u (call $__stack_dat_pop)))

		(local.set $oflags (call $__stack_dat_pop))
		(local.set $path_len (call $__stack_dat_pop))
		(local.set $path_ptr (call $__stack_dat_pop))
		(local.set $dirflags (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__wasi::path_open
				(call $__stack_dat_pop) ;; dir_fd
				(local.get $dirflags)
				(local.get $path_ptr)
				(local.get $path_len)
				(local.get $oflags)
				(local.get $fs_rights_base)
				(local.get $fs_rights_inheriting)
				(local.get $fdflags)
				(local.get $opened_fd_ptr)))
