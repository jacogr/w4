\ https://forth-standard.org/standard/core/FALSE

	: false ( -- false ) 0 ;

\ https://forth-standard.org/standard/core/TRUE

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

	: invert ( x -- !x ) -1 xor ;

\ https://forth-standard.org/standard/core/NEGATE

	: negate ( x -- -x ) invert 1+ ;

\ https://forth-standard.org/standard/core/Zerone

	: 0<> ( n -- flag ) 0= invert ;

\ https://forth-standard.org/standard/core/Zeroless

	-1 1 rshift invert constant msb

	: 0< ( n -- flag ) msb and 0<> ;

\ https://forth-standard.org/standard/core/Zeromore

	: 0> ( n -- flag )
		dup 0=
		swap 0<
		or invert
	;

\ mid-point require, we need the sp-n@ versions for <

require stack.ptr.f

\ https://forth-standard.org/standard/core/Equal

	: = ( x y -- flag ) - 0= ;

\ https://forth-standard.org/standard/core/ne

	: <> ( x y -- flag ) = invert ;

\ https://forth-standard.org/standard/core/less

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

	: > ( n m -- flag ) swap < ;

\ https://forth-standard.org/standard/core/Uless

	: u< ( u1 u2 -- f )
		swap msb xor
		swap msb xor
		<
	;

\ https://forth-standard.org/standard/core/Umore

	: u>  ( u1 u2 -- flag ) swap u< ;
