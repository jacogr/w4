
(;

	forth/math.wat

	Various math routines that are being used inside the builtins.

;)

	;;
	;; Equivalent um/mod in forth
	;;
	;; https://forth-standard.org/standard/core/UMDivMOD
	;;
	(func $__um_mod (param $lo i32) (param $hi i32) (param $div i32) (result i32 i32)
		(local $ud i64)
		(local $d i64)

		;; div == 0, -10 division by zero
		(call $__assert (local.get $div) (i32.const -10))

		;; hi >= div, -11 result out of range
		(call $__assert (i32.lt_u (local.get $hi) (local.get $div)) (i32.const -11))

		;; r
		(i32.wrap_i64
			(i64.rem_u
				;; ud = (u64)hi<<32 | (u64)lo
				(local.tee $ud
					(i64.or
						(i64.shl (i64.extend_i32_u (local.get $hi)) (i64.const 32))
						(i64.extend_i32_u (local.get $lo))))
				;; d = (u64)div
				(local.tee $d
					(i64.extend_i32_u (local.get $div)))))

		;; q
		(i32.wrap_i64 (i64.div_u (local.get $ud) (local.get $d)))
	)

	;;
	;; Equivalent to um* in forth
	;;
	;; https://forth-standard.org/standard/core/UMTimes
	;;
	(func $__um_mul (param $u1 i32) (param $u2 i32) (result i32 i32)
		(local $p i64)

		;; lo
		(i32.wrap_i64
			;; p = (u64)u1 * (u64)u2
			(local.tee $p
				(i64.mul
					(i64.extend_i32_u (local.get $u1))
					(i64.extend_i32_u (local.get $u2)))))

		;; hi
		(i32.wrap_i64 (i64.shr_u (local.get $p) (i64.const 32)))
	)
