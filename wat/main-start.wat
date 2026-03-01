		;; set the current alloc position (after exception, end of constant memory)
		(i32.store (global.get $PTR_ALLOC) (call $__excep_init))

		;; allocate dictionary
		(i32.store (global.get $PTR_PTR_WID_LIST) (call $__alloc (i32.mul (i32.const 16) (i32.const 4))))
		(i32.store (global.get $PTR_WID_CURR) (call $__store (global.get $PTR_WID_ORIG) (call $__dict_init (i32.const 1024))))
		(i32.store (i32.load (global.get $PTR_PTR_WID_LIST)) (i32.load (global.get $PTR_WID_CURR)))

		;; allocate stacks, all with global pointers
		(i32.store (global.get $PTR_PTR_STACK_DAT) (call $__stack_new))
		(i32.store (global.get $PTR_PTR_STACK_RET) (call $__stack_new))
		(i32.store (global.get $PTR_PTR_STACK_SRC) (call $__stack_new))

		;; set the alloc start/end for checks
		(i32.store (global.get $PTR_ALLOC_MIN) (i32.load (global.get $PTR_ALLOC)))
		(i32.store (global.get $PTR_ALLOC_MAX) (global.get $W4_FORTH_START))
