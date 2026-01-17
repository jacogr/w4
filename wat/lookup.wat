
(;

	lookup.wat

	Create and manage lookup lists. These hash tables are used for
	lookup of values, e.g. for dictionary entries and include/require.
	It is a layer that works in addition to the list functions, providing
	buckets on top of the lists for easier (closer to O(1)) lookups.

;)

	;; hash index object layout:
	;;
	;; 		buckets (i32): array of bucket pointers, 2^n
	;;		mask (i32)   : 2^n - 1, mask for bucket lookup
	(global $IDX_HI_BUCKETS i32 (i32.const 0))
	(global $IDX_HI_MASK    i32 (i32.const 4))
	(global $SIZEOF_HINDEX  i32 (i32.const 8))

	;;
	;; Finds an entry in a lookup list by hash & length
	;;
	(func $__lookup_find (param $ptr_list i32) (param $str i32) (param $len i32) (param $hash i32) (result i32)
		(local $ptr_ent i32)
		(local $ptr_val i32)
		(local $hi i32)

		;; load index
		(local.set $hi (call $__list_get_owner (local.get $ptr_list)))

		;; ptr_ent = buckets[hash & mask]
		(local.set $ptr_ent
			(i32.load
			(i32.add
				(call $__lookup_get_buckets (local.get $hi))
				(i32.shl
					(i32.and
						(local.get $hash)
						(call $__lookup_get_mask (local.get $hi)))
					(i32.const 2)))))

		;; walk through linked list until found (or end)
		(block $exit (loop $loop

			;; break out if we have a zero pointer, end of list
			(br_if $exit
				(i32.eqz (local.get $ptr_ent)))

			;; check for visible
			(call $__has_flag
				(call $__val_get_flags (local.tee $ptr_val
					(call $__val_get_value (local.get $ptr_ent))))
				(global.get $FLG_VISIBLE)) (if

				;; visible
				(then
					;; hashes match?
					(i32.eq
						(local.get $hash)
						(call $__iov_get_hash (local.get $ptr_val))) (if

						;; matching hashes
						(then
							;; length match?
							(i32.eq
								(local.get $len)
								(call $__iov_get_len (local.get $ptr_val))) (if

							;; matching lengths
							(then
								;; found if strings match
								(br_if $exit
									(call $__streqi_n
										(local.get $str)
										(call $__iov_get_str (local.get $ptr_val))
										(local.get $len))))

							;; no match on length, continue
							(else)))

						;; no match on hashes, continue
						(else)))

				;; invisible, continue
				(else))

			;; for next check, get previous
			(local.set $ptr_ent (call $__ent_get_link (local.get $ptr_ent)))

			;; continue
			br $loop))

		;; get the pointer to the actual entry
		local.get $ptr_ent
	)

	;;
	;; Create a new list on which we can perform lookups, this is fo
	;; both included files and the forth dictionary
	;;
	(func $__lookup_new (param $count i32) (result i32)
		(local $ptr i32)
		(local $hi i32)

		;; ensure count >= 256 and power of 2, -49 search-order overflow
		;; (assert only throwing in development, -49 unused elsewhere)
		(call $__assert
			(i32.and
				(i32.ge_u (local.get $count) (i32.const 256))
				;; (n & (n - 1)) == 0, only valid if n > 0
				(i32.eqz
					(i32.and
						(local.get $count)
						(i32.sub (local.get $count) (i32.const 1)))))
			(i32.const -49))

		;; allocate hi & buckets, set mask
		(call $__lookup_set_buckets
			(local.tee $hi (call $__alloc (global.get $SIZEOF_HINDEX)))
			(call $__alloc (i32.shl (local.get $count) (i32.const 2)))) ;; count * 4 (i32)
		(call $__lookup_set_mask (local.get $hi) (i32.sub (local.get $count) (i32.const 1)))

		;; create list, set owner = hi
		(call $__list_set_owner
			(local.tee $ptr (call $__list_new))
			(local.get $hi))

		;; return list
		local.get $ptr
	)

	;;
	;; Append an entry to a lookup list. This adds it both to the linked list
	;; and to the appropriate bucket
	;;
	(func $__lookup_append (param $ptr_list i32) (param $hash i32) (param $ptr_xt i32) (result i32)
		(local $ent i32)
		(local $hi i32)
		(local $bptr i32)

		;; append to list & get newly created entry value
		(call $__list_append (local.get $ptr_list) (local.get $ptr_xt))

		;; get entry & hash index from list
		(local.set $ent (call $__list_get_tail (local.get $ptr_list)))
		(local.set $hi (call $__list_get_owner (local.get $ptr_list)))

		;; bptr = &buckets[hash & mask]
		(local.set $bptr
			(i32.add
				(call $__lookup_get_buckets (local.get $hi))
				(i32.shl
					(i32.and
						(local.get $hash)
						(call $__lookup_get_mask (local.get $hi)))
					(i32.const 2))))

		;; ent.hprev = old head
		(call $__ent_set_link
			(local.get $ent)
			(i32.load (local.get $bptr)))

		;; bucket head = ent
		(i32.store (local.get $bptr) (local.get $ent))

		;; return entry
		local.get $ent
	)

	;;
	;; Lookup helpers
	;;

	(func $__lookup_get_buckets (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_HI_BUCKETS))))

	(func $__lookup_set_buckets (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_HI_BUCKETS)) (local.get $val)))

	(func $__lookup_get_mask (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_HI_MASK))))

	(func $__lookup_set_mask (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_HI_MASK)) (local.get $val)))
