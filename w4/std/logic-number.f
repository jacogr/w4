m4_require(<!std/logic-base.f!>)
m4_require(<!std/stack-base.f!>)
m4_require(<!std/stack-ptr.f!>)

\ https://forth-standard.org/standard/core/less
\
\ flag is true if and only if n1 is less than n2.

	: < ( n m -- flag )
		\ With d = n-m, the sign of d ^ ((n ^ m) & (n ^ d)) gives n < m.
		\ Equal signs use d's sign; different signs use n's, even when d overflows.
		2dup -				( n m -- n m d )
		sp-2@ sp-2@ xor		( n m d -- n m d signs )
		sp-3@ sp-2@ xor		( n m d signs -- n m d signs correction )
		and xor 0<			( n m d signs correction -- n m flag )
		2nip				( n m flag -- flag )
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
