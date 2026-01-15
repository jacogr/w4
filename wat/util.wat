
(;

	util.wat

	General utilities that don't fit into another/specific bucket.

;)

	;;
	;; Does a pass-through i32 store, returning the value
	;;
	(func $__store (param $ptr i32) (param $val i32) (result i32)
		(i32.store (local.get $ptr) (local.get $val))
		local.get $val
	)

	;;
	;; Checks if a flag is set on a number
	;;
	(func $__has_flag (param $val i32) (param $flag i32) (result i32)
		(i32.eq
			(local.get $flag)
			(i32.and
				(local.get $val)
				(local.get $flag)))
	)
