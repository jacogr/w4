
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

	;;
	;; Helpers for PTR_LINE_OFF = >IN and PTR_LINE_IOV = SOURCE
	;;

	(func $__line_clear
		(call $__line_set_off_ptr__ (i32.const 0))
		(call $__line_set_iov__ (i32.const 0))
	)

	(func $__line_set (param $iov i32) (param $off_ptr i32)
		(call $__line_set_off_ptr__ (local.get $off_ptr))
		(call $__line_set_iov__ (local.get $iov))
	)

	(func $__line_set_off (param $v i32)
		(local $ptr i32)

		;; valid offset ptr
		(call $__assert_ptr (local.tee $ptr (call $__line_get_off_ptr__)))

		;; store
		(i32.store (local.get $ptr) (local.get $v)))

	(func $__line_get_off (result i32)
		(i32.load (call $__line_get_off_ptr__)))

	(func $__line_get_iov (result i32)
		(i32.load (global.get $PTR_LINE_IOV)))

	;;
	;; Never accessed out of this location
	;;

	(func $__line_get_off_ptr__ (result i32)
		(i32.load (global.get $PTR_PTR_LINE_OFF)))

	(func $__line_set_off_ptr__ (param $v i32)
		(i32.store (global.get $PTR_PTR_LINE_OFF) (local.get $v)))

	(func $__line_set_iov__ (param $v i32)
		(i32.store (global.get $PTR_LINE_IOV) (local.get $v)))
