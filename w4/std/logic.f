\ https://forth-standard.org/standard/core/FALSE
\
\ Return a false flag.

	: FALSE ( -- false ) 0 ;

\ https://forth-standard.org/standard/core/TRUE
\
\ Return a true flag, a single-cell value with all bits set.

	: TRUE ( -- true ) 0 0= ;

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

	: INVERT ( x -- !x ) -1 xor ;

\ https://forth-standard.org/standard/core/NEGATE
\
\ Negate n1, giving its arithmetic inverse n2.

	: NEGATE ( x -- -x ) invert 1+ ;

\ https://forth-standard.org/standard/core/Zerone
\
\ lag is true if and only if x is not equal to zero.

	: 0<> ( n -- flag ) 0= invert ;

\ https://forth-standard.org/standard/core/Zeroless
\
\ lag is true if and only if n is less than zero.

	-1 1 rshift invert constant MSB

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

\ mid-point include, we need the sp-n@ versions for <

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
