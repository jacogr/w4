
(;

	memory-alloc.wat

	Memory management.

;)

	;;
	;; Allocates a section of memory and returns the address
	;;
	(func $__alloc (export "alloc") (param $size i32) (result i32)
		;; allocate w/ address alignment
		(call $__alloc_inner
			(i32.and
				(i32.add
					(i32.load (global.get $PTR_ALLOC))
					(i32.const 3))
				(i32.const -4))
			(local.get $size))
	)

	;;
	;; Internal function with pointer & address allocation
	;;
	(func $__alloc_inner (param $ptr i32) (param $size i32) (result i32)
		(local $nxt i32)

		;; ensure max memory > next pointer, -23 address alignment exception
		(call $__assert
			(i32.gt_u
				(global.get $SIZEOF_MEMORY_MAX)
				(local.tee $nxt
					(i32.add (local.get $ptr) (local.get $size))))
			(i32.const -23))

		;; update the next pointer with the calculated size
		(i32.store (global.get $PTR_ALLOC) (local.get $nxt))

		;; return pointer to allocated area
		local.get $ptr
	)

	;;
	;; Allocate a new known structure, setting the flags directly
	;; (useful for lists, list items and xt)
	;;
	(func $__new (param $size i32) (param $flags i32) (result i32)
		(local $ptr i32)

		;; create item, set flags
		(call $__val_set_flags
			(local.tee $ptr (call $__alloc (local.get $size)))
			(local.get $flags))

		;; return pointer
		local.get $ptr
	)

	;;
	;; Allocate a stcak structure
	;;
	(func $__stack_new (result i32)
		(call $__alloc (i32.mul (i32.add (global.get $STACK_MAX) (i32.const 1)) (i32.const 4))))
