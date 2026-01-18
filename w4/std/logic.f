\ https://forth-standard.org/standard/core/FALSE
\
\ Return a false flag.

	: false ( -- false ) 0 ;

\ https://forth-standard.org/standard/core/TRUE
\
\ Return a true flag, a single-cell value with all bits set.

	: true ( -- true ) 0 0= ;

\ https://forth-standard.org/standard/core/OneMinus
\
\ Subtract one (1) from n1 | u1 giving the difference n2 | u2.

	: 1- ( n1 | u1 -- n2 | u2 ) 1 - ;

\ https://forth-standard.org/standard/core/OnePlus
\
\ Add one (1) to n1 | u1 giving the sum n2 | u2.

	: 1+ ( n1 | u1 -- n2 | u2 ) 1 + ;

\ https://forth-standard.org/standard/core/INVERT
\
\ Invert all bits of x1, giving its logical inverse x2.

	: invert ( x -- !x ) -1 xor ;

\ https://forth-standard.org/standard/core/NEGATE
\
\ Negate n1, giving its arithmetic inverse n2.

	: negate ( x -- -x ) invert 1+ ;

\ https://forth-standard.org/standard/core/Zerone
\
\ lag is true if and only if x is not equal to zero.

	: 0<> ( n -- flag ) 0= invert ;

\ https://forth-standard.org/standard/core/Zeroless
\
\ lag is true if and only if n is less than zero.

	-1 1 rshift invert constant msb

	: 0< ( n -- flag ) msb and 0<> ;

\ https://forth-standard.org/standard/core/Zeromore
\
\ flag is true if and only if n is greater than zero.

	: 0> ( n -- flag )
		dup 0=
		swap 0<
		or invert
	;

\ https://forth-standard.org/standard/core/Equal
\
\ flag is true if and only if x1 is bit-for-bit the same as x2.

	: = ( x y -- flag ) xor 0= ;

\ https://forth-standard.org/standard/core/ne
\
\ lag is true if and only if x1 is not bit-for-bit the same as x2.

	: <> ( x y -- flag ) = invert ;

\ mid-point require, we need the sp-n@ versions for <

require stack.ptr.f

\ https://forth-standard.org/standard/core/less
\
\ flag is true if and only if n1 is less than n2.

	: < ( n m -- flag )
		over over		\ n m n m
		xor 0<			\ n m diff			\ diff = signs differ?
		sp-2@ 0<		\ n m diff sn		\ sn = n 0<
		sp-3@ sp-3@		\ n m diff sn n m	\ 2over
		- 0<			\ n m diff sn sd	\ sd = (n-m) 0<

		swap			\ n m diff sd sn
		over xor		\ n m diff sd (sd^sn)
		sp-2@ and		\ n m diff sd ((sd^sn)&diff)
		xor				\ n m diff result	\ sd^((sd^sn)&diff)

		swap drop		\ n m result
		swap drop		\ n result
		swap drop		\ result
	;

\ https://forth-standard.org/standard/core/more
\
\ flag is true if and only if n1 is greater than n2.

	: > ( n m -- flag ) swap < ;

\ https://forth-standard.org/standard/core/Uless
\
\ flag is true if and only if u1 is less than u2.

	: u< ( u1 u2 -- f )
		swap msb xor
		swap msb xor
		<
	;

\ https://forth-standard.org/standard/core/Umore
\
\ flag is true if and only if u1 is greater than u2.

	: u>  ( u1 u2 -- flag ) swap u< ;
