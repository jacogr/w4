\ https://forth-standard.org/standard/core/FALSE

	: false ( -- false ) 0 ;

\ https://forth-standard.org/standard/core/TRUE

	: true ( -- true ) 0 0= ;

\ https://forth-standard.org/standard/core/OneMinus

	: 1- ( n -- n-- ) 1 - ;

\ https://forth-standard.org/standard/core/OnePlus

	: 1+ ( n -- n++ ) 1 + ;

\ 	: xor ( a b -- a^b )
\   over over or               \ a b ob
\   sp@ $2 cells - @
\   sp@ $2 cells - @
\ and     \ a b ob ab
\   -                     \ a b (ob-ab)
\   swap drop swap drop	\ nip nip
\ ;

\ : or ( a b -- a|b )
\ 	over over xor              \ a b ax
\   sp@ $2 cells - @
\   sp@ $2 cells - @
\ and     \ a b ox ab
\   +                     \ a b (ax+ab)
\   sp@ $2 cells - !
\   drop	\ nip nip
\ \  swap drop swap drop            \ drop original a b
\ ;

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

require w4/std/stack.ptr.f

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
