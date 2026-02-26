		(local $lo i32)
		(local $hi i32)
		(local $mul i32)
		(local $div i32)
		(local $qhi i32)
		(local $qlo i32)
		(local $rem i32)

		(local.set $div (call $__stack_dat_pop))
		(local.set $mul (call $__stack_dat_pop))
		(local.set $hi (call $__stack_dat_pop))
		(local.set $lo (call $__stack_dat_pop))

		;; perform operation
		(call $__um_star_slash_mod
			(local.get $lo)
			(local.get $hi)
			(local.get $mul)
			(local.get $div))

		;; gather results
		(local.set $qhi)
		(local.set $qlo)
		(local.set $rem)

		;; push to stack
		(call $__stack_dat_push (local.get $rem))
		(call $__stack_dat_push (local.get $qlo))
		(call $__stack_dat_push (local.get $qhi))
