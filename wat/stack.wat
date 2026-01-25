(;

	stack.wat

	Stack management. A stack is a list of i32 items (STACK_MAX + 1),
	where the count is stored in the first location. It allows for
	adding values (push), removing (pop) as well as convenience functions
	suck as peeking or retrieving the count.

;)

	;; maxiumum entries on a stack
	(global $STACK_MAX i32 (i32.const 255))

	;;
	;; Retrieve the specified stack pointer
	;;
	;; Calculated via loading the count and multiplying this by the size of
	;; the entries (i32, 4 bytes).
	;;
	(func $__stack_ptr (param $o i32) (param $ptr i32) (result i32)
		;; existing stack count, -4 stack underflow (-6 return)
		 (call $__assert
			(i32.gt_s
				(i32.load (local.get $ptr))
				(i32.const 0))
			(i32.sub (i32.const -4) (local.get $o)))

		;; calculate the stack pointer based on count
		(i32.add
			(local.get $ptr)
			(i32.mul
				(i32.load (local.get $ptr))
				(i32.const 4)))
	)

	;;
	;; Push data to a stack
	;;
	(func $__stack_push (param $o i32) (param $ptr i32) (param $val i32)
		(local $count i32)

		;; check that we have enough space, -3 stack overflow (-5 return)
		 (call $__assert
			(i32.lt_u
				(local.tee $count (i32.add (i32.load (local.get $ptr)) (i32.const 1)))
				(global.get $STACK_MAX))
			(i32.sub (i32.const -3) (local.get $o)))

		;; store the updated count
		(i32.store (local.get $ptr) (local.get $count))

		;; store the value to the ptr + offset
		(i32.store
			(call $__stack_ptr (local.get $o) (local.get $ptr))
			(local.get $val))
	)

	;;
	;; Peek data from a stack
	;;
	(func $__stack_peek (param $o i32) (param $ptr i32) (result i32)
		;; load value at top of stack for return
		(i32.load (call $__stack_ptr (local.get $o) (local.get $ptr)))
	)

	;;
	;; Peek the nth element from a stack without popping.
	;;
	;; idx is 1..count (1 = first entry above count cell, count = top of stack)
	;;
	(func $__stack_peek_at (param $o i32) (param $ptr i32) (param $idx i32) (result i32)
		;; assert idx >= 1 & idx <= count
		(call $__assert
			(i32.and
				(i32.ge_u (local.get $idx) (i32.const 1))
				(i32.le_u (local.get $idx) (i32.load (local.get $ptr))))
			(i32.sub (i32.const -4) (local.get $o)))

		;; load element at: ptr + idx*4
		(i32.load
			(i32.add
				(local.get $ptr)
				(i32.mul (local.get $idx) (i32.const 4))))
	)

	;;
	;; Pop data from a stack
	;;
	(func $__stack_pop (param $o i32) (param $ptr i32) (result i32)
		;; return of tos
		(call $__stack_peek (local.get $o) (local.get $ptr))

		;; decrement the count
		(i32.store
			(local.get $ptr)
			(i32.sub
				(i32.load (local.get $ptr))
				(i32.const 1)))
	)

	;;
	;; Stack helpers
	;;

	;; data

	(func $__stack_new (result i32)
		(call $__alloc (i32.mul (i32.add (global.get $STACK_MAX) (i32.const 1)) (i32.const 4))))

	(func $__stack_dat_pop (result i32)
		(call $__stack_pop (i32.const 0) (global.get $stack_dat)))

	(func $__stack_dat_2pop (result i32 i32)
		(local $top i32)

		(local.set $top (call $__stack_dat_pop))

		(call $__stack_dat_pop)
		(local.get $top))

	(func $__stack_dat_push (param $val i32)
		(call $__stack_push  (i32.const 0) (global.get $stack_dat) (local.get $val)))

	(func $__stack_dat_2push (param $a i32) (param $b i32)
		(call $__stack_dat_push (local.get $a))
		(call $__stack_dat_push (local.get $b)))

	;; return

	(func $__stack_ret_count (result i32)
		(i32.load (global.get $stack_ret)))

	(func $__stack_ret_pop (result i32)
		(call $__stack_pop (i32.const 2) (global.get $stack_ret)))

	(func $__stack_ret_push (param $val i32)
		(call $__stack_push (i32.const 2) (global.get $stack_ret) (local.get $val)))

	(func $__stack_ret_peek (result i32)
		(call $__stack_ret_count) (if (result i32)

			;; have a count, get top
			(then (call $__stack_peek (i32.const 2) (global.get $stack_ret)))

			;; no count, return -1
			(else (i32.const -1))))

	;; local values

	(func $__stack_loc_peek_at (param $idx i32) (result i32)
		(local $base i32)

		;; get base offset from frame stack
		(local.set $base
			(i32.load
				(i32.mul
					(i32.const 4)
					(i32.add
						(i32.load (i32.load (global.get $PTR_PTR_LOC_FRAME)))
						(i32.const 1)))))

		;; load specific value
		(i32.load
			(i32.add
				(i32.load (global.get $PTR_PTR_LOC_VALUE))
				(i32.mul
					(i32.const 4)
					(i32.add
						(i32.add (local.get $idx) (local.get $base))
						(i32.const 1))))))
