
(;

	list-entry.wat

	List entries are effectively headers over values that allows
	for list traversal. the "entry" is the header with next/prev/etc.
	and the value (as stored in the entry) is an extended iov.

;)

	;; offsets for linked list entries
	;;
	;;		prev (i32),	previous pointer
	;;		next (i32),	next pointer
	;;		link (i32), for instructions, the definition, for definitions, the bucket previous
	;;		flags (i32)
	;;		value (i32)
	(global $IDX_ENT_PREV    i32 (i32.const 0))
	(global $IDX_ENT_NEXT    i32 (i32.const 4))
	(global $IDX_ENT_LINK    i32 (i32.const 8))
	(global $IDX_ENT_FLAGS   i32 (i32.const 12)) ;; shared, always at 12
	(global $IDX_ENT_VALUE   i32 (i32.const 16))
	(global $SIZEOF_ENTRY    i32 (i32.const 20))

	;; offsets for list values, list -> ent -> value
	;; follows after iov and iov, iov_extended
	;;
	;;		iov (i32) (i32) (i32), fields from 0..11
	;;   	flags (i32)
	;;		value (i32) (cfa, specific per xt type)
	(global $IDX_VAL_FLAGS i32 (i32.const 12)) ;; shared, always at 12
	(global $IDX_VAL_VALUE i32 (i32.const 16))
	(global $SIZEOF_VAL    i32 (i32.const 20))

	;; entry flags stored in list entries (0, 2^0, 2^1, 2^2, ...)
	(global $FLG_ANY 	    i32 (i32.const 0xc0de0000)) ;; validity of xt
	(global $FLG_VISIBLE    i32 (i32.const 0xc0de0001))
	(global $FLG_IMMEDIATE  i32 (i32.const 0xc0de0002))
	(global $FLG_VARIANT    i32 (i32.const 0xc0de0004)) ;; e.g. literal types, does types
	(global $FLG_ASM     	i32 (i32.const 0xc0de0010))
	(global $FLG_TKN     	i32 (i32.const 0xc0de0020))
	(global $FLG_LIT        i32 (i32.const 0xc0de0040))
	(global $FLG_LITD       i32 (i32.const 0xc0de0044))
	(global $FLG_DO_MARK    i32 (i32.const 0xc0de0080))
	(global $FLG_DO_EXEC    i32 (i32.const 0xc0de0084))
	(global $FLG_LIST		i32 (i32.const 0xdeadfeed))
	(global $FLG_ITEM		i32 (i32.const 0xfeedc0de))

	;;
	;; Create a list value (don't add as of yet)
	;;
	(func $__val_new (param $str i32) (param $len i32) (param $hash i32) (param $val i32) (param $flags i32) (result i32)
		(local $ptr i32)

		;; store item details, value & flags
		(call $__val_set_value
			(local.tee $ptr
				(call $__iov_fill
					(call $__new (global.get $SIZEOF_VAL) (local.get $flags))
					(local.get $str)
					(local.get $len)
					(local.get $hash)))
			(local.get $val))

		;; return pointer
		local.get $ptr
	)

	;;
	;; Duplicates a list value (don't add as of yet)
	;;
	(func $__val_dup (param $src i32) (result i32)
		;; store item details, value & flags
		(call $__val_new
			(call $__iov_get_str_len (local.get $src))
			(i32.const 0)
			(call $__val_get_value (local.get $src))
			(call $__val_get_flags (local.get $src)))
	)

	;;
	;; Helpers for list values
	;;

	(func $__val_get_flags (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_VAL_FLAGS))))

	(func $__val_set_flags (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_VAL_FLAGS)) (local.get $val)))

	(func $__val_get_value (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_VAL_VALUE))))

	(func $__val_set_value (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_VAL_VALUE)) (local.get $val)))


	;;
	;; Helpers for list entries
	;;

	(func $__ent_get_prev (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_ENT_PREV))))

	(func $__ent_set_prev (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_ENT_PREV)) (local.get $val)))

	(func $__ent_get_next (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_ENT_NEXT))))

	(func $__ent_set_next (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_ENT_NEXT)) (local.get $val)))

	(func $__ent_get_link (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_ENT_LINK))))

	(func $__ent_set_link (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_ENT_LINK)) (local.get $val)))
