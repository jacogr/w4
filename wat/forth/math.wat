
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

	;;
	;; Non-standard: um*/mod
	;; ( lo hi u_mul u_div -- rem qlo qhi )
	;;
	;; Computes: t = (u64(hi:lo) * u_mul)  [96-bit]
	;; Then:     (q, rem) = t / u_div
	;; Returns:  rem (i32), qlo (i32), qhi (i32)
	;;
	(func $__um_star_slash_mod (param $lo i32) (param $hi i32) (param $mul i32) (param $div i32) (result i32 i32 i32)
		(local $p i64)        ;; (u64)lo * (u64)mul
		(local $q i64)        ;; (u64)hi * (u64)mul

		(local $p0 i32)       ;; low 32 of p
		(local $p1 i32)       ;; high 32 of p
		(local $q0 i32)       ;; low 32 of q
		(local $q1 i32)       ;; high 32 of q

		(local $mid i32)      ;; p1 + q0
		(local $carry i32)    ;; carry from p1+q0
		(local $p2 i32)       ;; top 32 of 96-bit product = q1 + carry

		(local $d i64)        ;; divisor as i64
		(local $top i64)      ;; top 64 of 96-bit product: (p2<<32)|mid
		(local $r1 i64)       ;; remainder after first division
		(local $qhi i64)      ;; high 32 of quotient

		(local $bot i64)      ;; bottom 64 for second division: (r1<<32)|p0
		(local $qlo i64)      ;; low 32 of quotient
		(local $rem i64)      ;; final remainder

		;; div == 0, -10 division by zero
		(call $__assert (local.get $div) (i32.const -10))

		;; d = (u64)div
		(local.set $d (i64.extend_i32_u (local.get $div)))

		;; p = (u64)lo * (u64)mul
		(local.set $p
			(i64.mul
				(i64.extend_i32_u (local.get $lo))
				(i64.extend_i32_u (local.get $mul))))

		;; q = (u64)hi * (u64)mul
		(local.set $q
			(i64.mul
				(i64.extend_i32_u (local.get $hi))
				(i64.extend_i32_u (local.get $mul))))

		;; split p into p0/p1
		(local.set $p0 (i32.wrap_i64 (local.get $p)))
		(local.set $p1 (i32.wrap_i64 (i64.shr_u (local.get $p) (i64.const 32))))

		;; split q into q0/q1
		(local.set $q0 (i32.wrap_i64 (local.get $q)))
		(local.set $q1 (i32.wrap_i64 (i64.shr_u (local.get $q) (i64.const 32))))

		;; mid = p1 + q0, carry if overflow
		(local.set $mid (i32.add (local.get $p1) (local.get $q0)))
		(local.set $carry
			(select
				(i32.const 1)
				(i32.const 0)
				(i32.lt_u (local.get $mid) (local.get $p1))))

		;; p2 = q1 + carry
		(local.set $p2 (i32.add (local.get $q1) (local.get $carry)))

		;; p2 >= div => quotient out of range (would exceed 64-bit), -11
		(call $__assert (i32.lt_u (local.get $p2) (local.get $div)) (i32.const -11))

		;; top = (u64)p2<<32 | (u64)mid
		(local.set $top
			(i64.or
				(i64.shl (i64.extend_i32_u (local.get $p2)) (i64.const 32))
				(i64.extend_i32_u (local.get $mid))))

		;; First division: top / div => qhi, r1
		(local.set $qhi (i64.div_u (local.get $top) (local.get $d)))
		(local.set $r1  (i64.rem_u (local.get $top) (local.get $d)))

		;; bot = (r1<<32) | p0
		(local.set $bot
			(i64.or
				(i64.shl (local.get $r1) (i64.const 32))
				(i64.extend_i32_u (local.get $p0))))

		;; Second division: bot / div => qlo, rem
		(local.set $qlo (i64.div_u (local.get $bot) (local.get $d)))
		(local.set $rem (i64.rem_u (local.get $bot) (local.get $d)))

		;; return: rem, qlo, qhi
		(i32.wrap_i64 (local.get $rem))
		(i32.wrap_i64 (local.get $qlo))
		(i32.wrap_i64 (local.get $qhi))
	)

	;;
	;; non-standard m*/mod (signed, symmetric):
	;; (lo hi n_mul n_div) -> (rem qlo qhi)
	;;
	(func $__m_star_slash_mod (param $lo i32) (param $hi i32) (param $mul i32) (param $div i32) (result i32 i32 i32)
		(local $signD i32)    ;; sign of d1 (from hi)
		(local $signM i32)    ;; sign of mul
		(local $signT i32)    ;; sign of product t = d1*mul  (signD xor signM)
		(local $signV i32)    ;; sign of divisor
		(local $signQ i32)    ;; sign of quotient q = signT xor signV

		(local $alo i32)      ;; |d1| lo
		(local $ahi i32)      ;; |d1| hi
		(local $amul i32)     ;; |mul|
		(local $adiv i32)     ;; |div|

		(local $rem i32)
		(local $qlo i32)
		(local $qhi i32)

		;; div == 0 -> -10
		(call $__assert (local.get $div) (i32.const -10))

		;; signs
		(local.set $signD (i32.shr_s (local.get $hi) (i32.const 31)))   ;; 0 or -1
		(local.set $signM (i32.shr_s (local.get $mul) (i32.const 31)))  ;; 0 or -1
		(local.set $signT (i32.xor (local.get $signD) (local.get $signM)))

		(local.set $signV (i32.shr_s (local.get $div) (i32.const 31)))  ;; 0 or -1
		(local.set $signQ (i32.xor (local.get $signT) (local.get $signV)))

		;; |mul|, |div|
		(local.set $amul
			(select
				(i32.sub (i32.const 0) (local.get $mul))
				(local.get $mul)
				(local.get $signM)))
		(local.set $adiv
			(select
				(i32.sub (i32.const 0) (local.get $div))
				(local.get $div)
				(local.get $signV)))

		;; |d1| as (alo,ahi) = abs64(lo,hi) using two's complement negate if signD
		;; If signD != 0: (lo,hi) = - (lo,hi)
		(local.set $alo (local.get $lo))
		(local.set $ahi (local.get $hi))
		(local.get $signD) (if
			(then
				;; negate 64-bit in two 32-bit parts: alo = ~alo + 1, ahi = ~ahi + carry
				(local.set $alo (i32.add (i32.xor (local.get $alo) (i32.const -1)) (i32.const 1)))
				(local.set $ahi
					(i32.add
						(i32.xor (local.get $ahi) (i32.const -1))
						(select (i32.const 1) (i32.const 0) (i32.eqz (local.get $alo))))))
			(else))

		;; unsigned core: um*/mod(|d1|, |mul|, |div|) -> (rem qlo qhi)
		(call $__um_star_slash_mod
			(local.get $alo)
			(local.get $ahi)
			(local.get $amul)
			(local.get $adiv))
		(local.set $qhi)
		(local.set $qlo)
		(local.set $rem)

		;; apply quotient sign if signQ != 0: negate (qlo,qhi) as signed 64
		(local.get $signQ) (if
			(then
				;; q = -q
				(local.set $qlo (i32.add (i32.xor (local.get $qlo) (i32.const -1)) (i32.const 1)))
				(local.set $qhi
					(i32.add
					(i32.xor (local.get $qhi) (i32.const -1))
					(select (i32.const 1) (i32.const 0) (i32.eqz (local.get $qlo))))))
			(else))

		;; apply remainder sign to match product sign (signT): rem = -rem if signT != 0
		(local.get $signT) (if
			(then (local.set $rem (i32.sub (i32.const 0) (local.get $rem))))
			(else))

		;; return (rem qlo qhi)
		(local.get $rem)
		(local.get $qlo)
		(local.get $qhi)
	)

