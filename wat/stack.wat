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

		;; store the value to ptr + count*4
		(i32.store
			(i32.add
				(local.get $ptr)
				(i32.mul
					(local.get $count)
					(i32.const 4)))
			(local.get $val))
	)

	;;
	;; Peek data from a stack
	;;
	(func $__stack_peek (param $o i32) (param $ptr i32) (result i32)
		(local $count i32)

		;; existing stack count, -4 stack underflow (-6 return)
		(call $__assert
			(i32.gt_s
				(local.tee $count (i32.load (local.get $ptr)))
				(i32.const 0))
			(i32.sub (i32.const -4) (local.get $o)))

		;; load value at top of stack for return
		(i32.load
			(i32.add
				(local.get $ptr)
				(i32.mul
					(local.get $count)
					(i32.const 4))))
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

	(func $__stack_dat_pop (result i32)
		(call $__stack_pop (i32.const 0) (i32.load (global.get $PTR_PTR_STACK_DAT))))

	(func $__stack_dat_2pop (result i32 i32)
		(local $ptr i32)
		(local $count i32)
		(local $a i32)
		(local $top i32)

		(local.set $ptr (i32.load (global.get $PTR_PTR_STACK_DAT)))

		;; need at least 2 items on data stack
		(call $__assert
			(i32.ge_u
				(local.tee $count (i32.load (local.get $ptr)))
				(i32.const 2))
			(i32.const -4))

		;; top (x2)
		(local.set $top
			(i32.load
				(i32.add
					(local.get $ptr)
					(i32.mul
						(local.get $count)
						(i32.const 4)))))

		;; next (x1)
		(local.set $a
			(i32.load
				(i32.add
					(local.get $ptr)
					(i32.mul
						(i32.sub (local.get $count) (i32.const 1))
						(i32.const 4)))))

		;; drop both
		(i32.store
			(local.get $ptr)
			(i32.sub
				(local.get $count)
				(i32.const 2)))

		(local.get $a)
		(local.get $top))

	(func $__stack_dat_push (param $val i32)
		(call $__stack_push  (i32.const 0) (i32.load (global.get $PTR_PTR_STACK_DAT)) (local.get $val)))

	(func $__stack_dat_2push (param $a i32) (param $b i32)
		(call $__stack_dat_push (local.get $a))
		(call $__stack_dat_push (local.get $b)))

	;; return

	(func $__stack_ret_count (result i32)
		(i32.load (i32.load (global.get $PTR_PTR_STACK_RET))))

	(func $__stack_ret_pop (result i32)
		(call $__stack_pop (i32.const 2) (i32.load (global.get $PTR_PTR_STACK_RET))))

	(func $__stack_ret_push (param $val i32)
		(call $__stack_push (i32.const 2) (i32.load (global.get $PTR_PTR_STACK_RET)) (local.get $val)))

	;; local values

	(func $__stack_loc_peek_at (param $idx i32) (result i32)
		(local $base i32)

		;; base pointer to locals frame top
		(local.set $base (i32.load (global.get $PTR_LOC_VALUE_AT)))

		;; load value at index from frame start: base - (count*4) + (idx*4)
		(i32.load
			(i32.add
				(i32.sub
					(local.get $base)
					(i32.mul
						(i32.load (local.get $base))
						(i32.const 4)))
				(i32.mul
					(local.get $idx)
					(i32.const 4))))
	)
