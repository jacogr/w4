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
