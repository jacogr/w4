m4_require_w4(`std/logic-base.f')
m4_require_w4(`std/stack-base.f')
m4_require_w4(`std/stack-ptr.f')

\ https://forth-standard.org/standard/core/less
\
\ flag is true if and only if n1 is less than n2.

	: < ( n m -- flag )
		2dup			( n m -- n m n m )
		xor 0<			( n m n m -- n m diff )					\ diff = signs differ?
		sp-2@ 0<		( n m diff -- n m diff sn )				\ sn = n 0<
		2over			( n m diff sn -- n m diff sn n m )
		- 0<			( n m diff sn n m -- n m diff sn sd	)	\ sd = (n-m) 0<

		swap			( n m diff sn sd -- n m diff sd sn )
		over xor		( n m diff sd sn -- n m diff sd f1 )	\ f1 = (sd^sn)
		sp-2@ and		( n m diff sd f1 -- n m diff sd f2 )	\ f2 = f1 & diff
		xor				( n m diff sd f2 -- n m diff f	)		\ f = f2 ^ sd

		3nip			( n m diff f -- f )
	;

\ https://forth-standard.org/standard/core/more
\
\ flag is true if and only if n1 is greater than n2.

	: > ( n m -- flag ) swap < ;

\ https://forth-standard.org/standard/core/Uless
\
\ flag is true if and only if u1 is less than u2.

	: U< ( u1 u2 -- f )
		swap msb xor
		swap msb xor
		<
	;

\ https://forth-standard.org/standard/core/Umore
\
\ flag is true if and only if u1 is greater than u2.

	: U>  ( u1 u2 -- flag ) swap u< ;

\ https://forth-standard.org/standard/core/WITHIN
\
\ Perform a comparison of a test value n1 | u1 with a lower limit n2 | u2 and
\ an upper limit n3 | u3, returning true if either (n2 | u2 < n3 | u3 and
\ (n2 | u2 <= n1 | u1 and n1 | u1 < n3 | u3)) or (n2 | u2 > n3 | u3 and
\ (n2 | u2 <= n1 | u1 or n1 | u1 < n3 | u3)) is true, returning false
\ otherwise. An ambiguous condition exists n1 | u1, n2 | u2, and n3 | u3 are
\ not all the same type.

	: WITHIN ( test low high -- flag ) over - rot rot - u> ;
