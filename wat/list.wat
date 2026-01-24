
(;

	list.wat

	List management functions. Lists are used for dictionaries,
	inludes/requires and token lists.

;)

	;; offsets for linked list headers with memory layout in terms of cells:
	;;
	;; NOTE: As a shortcut, we ensure we have flags in every 4th position
	;; across list, item and xt (same helpers, same layout for any)
	;;
	;;	 	head (i32),
	;;		tail (i32),
	;;		owner (i32),
	;;		flags (i32),
	;;		file (i32),
	;;		row+col (i32)
	(global $IDX_LST_HEAD    i32 (i32.const 0))
	(global $IDX_LST_TAIL    i32 (i32.const 4))
	(global $IDX_LST_OWNER   i32 (i32.const 8))
	(global $IDX_LST_FLAGS   i32 (i32.const 12)) ;; shared, always at 12
	(global $IDX_LST_FILE    i32 (i32.const 16))
	(global $IDX_LST_ROW_COL i32 (i32.const 20))
	(global $SIZEOF_LIST     i32 (i32.const 24))

	;;
	;; Appends an entry to a list from the supplied values
	;;
	(func $__list_append (param $ptr_list i32) (param $ptr_xt i32)
		(local $ptr_head i32)
		(local $ptr_tail i32)
		(local $ptr_ent i32)

		;; we need valid list & entry, -9 invalid memory address
		(call $__assert
			(i32.eqz
				(i32.or
					(i32.eqz (local.get $ptr_list))
					(i32.eqz (local.get $ptr_xt))))
			(i32.const -9))

		;; set the values of the involved pointers
		(local.set $ptr_head (call $__list_get_head (local.get $ptr_list)))
		(local.set $ptr_tail (call $__list_get_tail (local.get $ptr_list)))
		(local.set $ptr_ent (call $__new (global.get $SIZEOF_ENTRY) (global.get $FLG_ITEM)))

		;; create a list entry (prev & ptr)
		(call $__ent_set_prev (local.get $ptr_ent) (local.get $ptr_tail))
		(call $__ent_set_link (local.get $ptr_ent) (local.get $ptr_list))
		(call $__val_set_value (local.get $ptr_ent) (local.get $ptr_xt))

		;; update the tail to entry
		(call $__list_set_tail (local.get $ptr_list) (local.get $ptr_ent))

		;; existing tail?
		(local.get $ptr_tail) (if

			;; existing tail, set this as next
			(then (call $__ent_set_next (local.get $ptr_tail) (local.get $ptr_ent)))

			;; no list tail to update
			(else))

		;; existing head?
		(local.get $ptr_head) (if

			;; current head, keep
			(then)

			;; nothing, use entry
			(else (call $__list_set_head (local.get $ptr_list) (local.get $ptr_ent))))
	)

	;;
	;; Inserts an item just before the end of the list
	;;
	;; Useful for instance in item lists where "exit" is
	;; always meant to be the last, so we can add that and
	;; then always just insert and have a valid-ish list
	;;
	(func $__list_insert (param $ptr_list i32) (param $ptr_xt i32)
		(local $ptr_tail i32)

		;; we need valid entry, -9 invalid memory address
		(call $__assert (local.get $ptr_xt) (i32.const -9))

		;; append with duplicated last entry (will swap value below)
		(call $__list_append
			(local.get $ptr_list)
			(call $__val_get_value (local.tee $ptr_tail
				(call $__list_get_tail (local.get $ptr_list)))))

		;; set the pointer of previous tail to this xt
		(call $__val_set_value (local.get $ptr_tail) (local.get $ptr_xt))
	)

	;;
	;; Create a new list of any type
	;;

	(func $__list_new (result i32)
		(call $__new (global.get $SIZEOF_LIST) (global.get $FLG_LIST))
	)

	;;
	;; Insert a token into the current active token list
	;;

	(func $__toks_insert (param $ptr i32)
		(call $__list_insert (global.get $list_toks) (local.get $ptr))
	)

	;;
	;; General list structure helpers
	;;

	(func $__list_get_head (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_LST_HEAD))))

	(func $__list_set_head (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_LST_HEAD)) (local.get $val)))

	(func $__list_get_tail (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_LST_TAIL))))

	(func $__list_set_tail (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_LST_TAIL)) (local.get $val)))

	(func $__list_get_owner (param $ptr i32) (result i32)
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_LST_OWNER))))

	(func $__list_set_owner (param $ptr i32) (param $val i32)
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_LST_OWNER)) (local.get $val)))

	(func $__list_set_file (param $ptr i32) (param $file i32) (param $row i32) (param $col i32)
		;; store the file
		(i32.store (i32.add (local.get $ptr) (global.get $IDX_LST_FILE)) (local.get $file))

		;; store the row/col
		(i32.store
			(i32.add (local.get $ptr) (global.get $IDX_LST_ROW_COL))
			(i32.or
				(i32.and (local.get $row) (i32.const 0xffff))
				(i32.shl (local.get $col) (i32.const 16))))
	)

	;; (file, row, col)
	(func $__list_get_file (param $ptr i32) (result i32 i32 i32)
		(local $rc i32)

		;; file
		(i32.load (i32.add (local.get $ptr) (global.get $IDX_LST_FILE)))

		;; row
		(i32.and
			(local.tee $rc (i32.load (i32.add (local.get $ptr) (global.get $IDX_LST_ROW_COL))))
			(i32.const 0xffff))

		;; col
		(i32.shr_u (local.get $rc) (i32.const 16))
	)

	;;
	;; Helpers to retrieve specific lists
	;;

	(func $__get_list_incl (result i32)
		(i32.load (global.get $PTR_PTR_INCL)))
