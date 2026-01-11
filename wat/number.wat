
(;

	number.wat

	Number handling routines. This covers conversion of number to/from
	string and number to/from character

;)

	;;
	;; Retrieves the current base
	;;
	(func $__get_base (result i32)
		(local $base i32)

		(local.tee $base (i32.load (global.get $PTR_BASE)))

		;; ensure base is valid, >= 2, <= 36, -40 invalid base
		(call $__assert
			(i32.and
				(i32.ge_u (local.get $base) (i32.const 2))
				(i32.le_u (local.get $base) (i32.const 36)))
			(i32.const -40))
	)

	;;
	;; Converts a base value to a character (lower only)
	;;
	(func $__num_to_chr (param $n i32) (result i32)
		(i32.add
			(local.get $n)
			(select
				;; alphabetic
				(i32.const 87) ;; 'a' = 97, 10 indicates first
				;; numeric
				(i32.const 48) ;; '0' = 48
				;; > than numeric space?
				(i32.ge_u (local.get $n) (i32.const 10))))
	)

	;;
	;; Converts a character number (upper & lower)
	;;
	(func $__chr_to_num (param $c i32) (result i32)
		;; needs to be >= '0' = 48
		(i32.ge_u
			(local.get $c)
			(i32.const 48)) (if (result i32)

			;; check at least uppercase 'A' = 65
			(then
				(i32.ge_u
					(local.get $c)
					(i32.const 65)) (if (result i32)

					;; alphabetic, any invalids would return value > base
					(then
						(i32.sub
							(local.get $c)
							(select
								;; lowercase, 10 is 'a' = 97
								(i32.const 87)
								;; uppercase, 10 is 'A' = 65
								(i32.const 55)
								;; check for lowercase, 'a' = 97
								(i32.ge_u (local.get $c) (i32.const 97)))))

					;; numeric
					(else
						(select
							;; in range, '0'..'9', '0' = 48
							(i32.sub (local.get $c) (i32.const 48))
							;; invalid, out of range
							(i32.const 255)
							;; check <= '9' = 57
							(i32.le_u (local.get $c) (i32.const 57))))))

			;; invalid, out of range
			(else (i32.const 255)))
	)

	;;
	;; Parses an string as decimal, binary, hexadecimal or 'char'
	;;
	;; The first return value is a flag, 0 on failure, 1 on success (or -1 for long),
	;; the second return value contains the actual parsed number.
	;;
	(func $__str_to_num (param $str i32) (param $len i32) (param $base i32) (result i32 i32)
		(local $idx i32)
		(local $ch i32)
		(local $ch_val i32)
		(local $val i32)
		(local $mul i32)
		(local $err i32)
		(local $long_set i32)
		(local $wait_val i32)

		;; defaults
		(local.set $mul (i32.const 1))
		(local.set $wait_val (i32.const 1))

		;; ---- char literal: '<c>' exactly (len == 3, assume [0] and [2] are quotes)
		(i32.and
			(i32.eq (local.get $len) (i32.const 3))
			(i32.and
				(i32.eq (local.tee $ch (i32.load8_u (local.get $str))) (i32.const 39))
				(i32.eq
					(i32.load8_u (i32.add (local.get $str) (i32.const 2)))
					(i32.const 39)))) (if

			;; character literal, return (value, flag)
			(then
				(return
					(i32.load8_u (i32.add (local.get $str) (i32.const 1)))
					(global.get $FLG_LIT))))

		;; check for decimal prefix, #
		(i32.eq (local.get $ch) (i32.const 35)) (if  ;; '#'

			;; decimal
			(then
				(local.set $base (i32.const 10))
				(local.set $idx  (i32.const 1)))

			;; non-decimal, check hex, $
			(else
				(i32.eq
					(local.get $ch)
					(i32.const 36)) (if

					;; hex
					(then
						(local.set $base (i32.const 16))
						(local.set $idx  (i32.const 1)))

					;; non hex, check binary %
					(else
						(i32.eq
							(local.get $ch)
							(i32.const 37)) (if

							;; binary
							(then
								(local.set $base (i32.const 2))
								(local.set $idx  (i32.const 1)))

							;; not a prefix
							(else))))))

		;; ---- optional sign at idx (only if idx < len)
		(i32.lt_u (local.get $idx) (local.get $len)) (if

			;; inside length, check for '-'
			(then
				(i32.eq
					(local.tee $ch (i32.load8_u (i32.add (local.get $str) (local.get $idx))))
					(i32.const 45)) (if

					;; negative
					(then
						(local.set $mul (i32.const -1))
						(local.set $idx (i32.add (local.get $idx) (i32.const 1))))

					;; maybe positive, check for '+'
					(else
						(i32.eq
							(local.get $ch)
							(i32.const 43)) (if

							;; positive, increment index
							(then (local.set $idx (i32.add (local.get $idx) (i32.const 1))))

							;; not a sign
							(else))))))

		;; ---- digit loop from idx
		(block $exit (loop $loop

			;; break if no more characters remaining
			(br_if $exit
				(i32.ge_u (local.get $idx) (local.get $len)))

			;; '.' long marker
			(i32.eq
				(local.tee $ch (i32.load8_u (i32.add (local.get $str) (local.get $idx))))
				(i32.const 46)) (if

				;; valid '.' only if:
				;; - we already saw a digit (wait_val==0)
				;; - not already long
				;; - '.' is last char
				(then
					(i32.and
						(i32.eqz (local.get $wait_val))
						(i32.and
							(i32.eqz (local.get $long_set))
							(i32.eq
								(i32.add (local.get $idx) (i32.const 1))
								(local.get $len)))) (if

						;; '.' in last position
						(then
							(local.set $long_set (i32.const 1))
							(local.set $idx (i32.add (local.get $idx) (i32.const 1)))
							(br $exit))

						;; '.' in invalid position
						(else
							(local.set $err (i32.const 1))
							(br $exit))))

				;; no '.' at the end
				(else))

			;; digit -> value, base check
			(br_if $exit
				(local.tee $err
					(i32.ge_u
						(local.tee $ch_val (call $__chr_to_num (local.get $ch)))
						(local.get $base))))

			;; accumulate
			(local.set $wait_val (i32.const 0))
			(local.set $val
				(i32.add
					(i32.mul (local.get $val) (local.get $base))
					(local.get $ch_val)))

			(local.set $idx (i32.add (local.get $idx) (i32.const 1)))
			br $loop))

		;; return (value, flag)
		(i32.mul (local.get $val) (local.get $mul))

		;; flag
		(select
			;; literal type based on long flag
			(select
				(global.get $FLG_LITD)
				(global.get $FLG_LIT)
				(local.get $long_set))
			;; invalid
			(i32.const 0)
			;; at least one digit and no error
			(i32.and
				(i32.eqz (local.get $wait_val))
				(i32.eqz (local.get $err))))
	)

	;;
	;; Fills a string from a specific number
	;;
	(func $__num_to_str (param $base i32) (param $abs i32) (param $is_neg i32) (result i32 i32) ;; (ptr, len)
		(local $cap i32)
		(local $buf i32)
		(local $end i32)
		(local $p i32)
		(local $pre i32)

		;; capacity: plenty for base2 i32 + sign + prefix
		(local.set $p
			(local.tee $end
				(i32.add
					(local.tee $buf (call $__alloc (local.tee $cap (i32.const 40))))
					(local.get $cap))))

		;; digits (do-while)
		(loop $loop

			;; store next digit
			(i32.store8
				(local.tee $p (i32.sub (local.get $p) (i32.const 1)))
				(call $__num_to_chr (i32.rem_u (local.get $abs) (local.get $base))))

			;; continue while value != 0
			(br_if $loop
				(i32.ne (local.tee $abs (i32.div_u (local.get $abs) (local.get $base))) (i32.const 0))))

		;; if negative, store sign
		(local.get $is_neg) (if

			;; negative value, store '-' = 45
			(then
				(i32.store8 (local.tee $p (i32.sub (local.get $p) (i32.const 1)))
				(i32.const 45))))

		;; pre = '%' for base 2, '$' for base 16, else 0
		(local.tee $pre
			(select
				(i32.const 37) ;; '%'
				(select
					(i32.const 36) ;; '$'
					(i32.const 0)
					(i32.eq (local.get $base) (i32.const 16)))
				(i32.eq (local.get $base) (i32.const 2)))) (if

			;; have a prefix, store it
			(then
				(i32.store8
					(local.tee $p (i32.sub (local.get $p) (i32.const 1)))
					(local.get $pre))))

		;; return (ptr, len)
		(local.get $p)
		(i32.sub (local.get $end) (local.get $p))
	)
