require logic.f
require loops.f
require stack.f

\ https://forth-standard.org/standard/core/DECIMAL

	: decimal ( -- ) #10 base ! ;

\ https://forth-standard.org/standard/core/HEX

	: hex ( -- ) $10 base ! ;

\ https://forth-standard.org/standard/core/ABS

	: abs ( n -- |n| ) dup 0< if negate then ;
	\ dup 0< tuck xor swap - ;

\ https://forth-standard.org/standard/core/StoD

	: s>d  ( n -- d ) dup 0< ;

\ https://forth-standard.org/standard/double/DPlus

	: um+ ( u1 u2 -- sum carry-flag )
		over >r +          \ sum          R: u1
		dup r> u<       \ sum carry    (sum u< u1)
	;

	: d+ ( lo1 hi1 lo2 hi2 -- lo3 hi3 )
		>r swap >r          \ lo1 lo2        R: hi2 hi1
		um+                 \ lo3 carry-flag
		1 and               \ lo3 carry(0|1)
		r> r> +             \ lo3 carry hiSum
		swap +              \ lo3 hi3
	;

\ https://forth-standard.org/standard/double/DNEGATE

	: dnegate ( lo hi -- lo' hi' )
		invert swap
		invert swap		\ ~lo ~hi
		1. d+			\ +1 as double
	;

\ https://forth-standard.org/standard/double/DABS

	: dabs ( lo hi -- lo' hi' ) dup 0< if dnegate then ;

\ https://forth-standard.org/standard/core/MTimes

	: m* ( n1 n2 -- lo hi )
		2dup xor 0< >r         \ R: sign (0|-1)
		abs swap abs
		um*
		r> if dnegate then
	;

	: m* ( n1 n2 -- lo hi )
		2dup			( n1 n2 -- n1 n2 n1 n2 )
		xor 0< >r   	( n1 n2 n1 n2 -- n1 n2 ) ( r: -- 0|-1 )
		abs swap abs	( n1 n2 -- |n1| |n2| )
		um*				( |n1| |n2| -- lo' hi' )
		r> if dnegate then
	;

\ https://forth-standard.org/standard/core/Times

	: * ( n1 n2 -- n3 ) m* drop ;

\ https://forth-standard.org/standard/core/SMDivREM

	: sm/rem  ( lo hi n -- rem quot )
		\ Save signD (from hi) on return stack
		over 0< >r                 \ R: signD

		\ Compute signQ = signN xor signD, and save it too.
		\ This leaves DS back at lo hi n.
		dup 0< r@ xor >r            \ R: signD signQ

		\ Make operands positive and do unsigned division
		abs >r                      \ DS: lo hi        R: signD signQ |n|
		dabs                         \ DS: |d|
		r>                           \ DS: |d| |n|
		um/mod                       \ DS: rem quot

		\ Apply quotient sign (signQ), then remainder sign (signD)
		r> if negate then            \ rem quot'
		swap
		r> if negate then            \ quot' rem'
		swap                         \ rem' quot'
	;

\ https://forth-standard.org/standard/core/FMDivMOD

	: fm/mod ( lo hi n -- r q )
		dup >r                    \ lo hi n        R: n
		sm/rem                    \ r q            R: n
		over dup 0<>              \ r q r nz
		swap 0<                   \ r q nz sign(r)
		r@ 0< xor                 \ r q nz mismatch
		and                       \ r q adjust?

		if
			1- swap r> + swap	\ r+n q-1
		else
			r> drop
		then
	;

\ https://forth-standard.org/standard/core/DivMOD

	\ As per C
	: /mod ( n1 n2 -- q r ) >r s>d r> sm/rem ;

	\ Floored
	\ : /mod ( n1 n2 -- q r ) >r s>d r> fm/mod ;

	: u/mod  ( u d -- urem uquot )
		0 swap	( u d -- ulo 0 d )
		um/mod 	( ulo 0 d -- ur uq )
	;

\ https://forth-standard.org/standard/core/Div

	: / ( q r - r ) /mod nip ;

	: u/ u/mod nip ;

	: um/ um/mod nip ;

\ https://forth-standard.org/standard/core/MOD

	: mod ( q r - q ) /mod drop ;

\ https://forth-standard.org/standard/core/TwoTimes
\
\ x' is the result of shifting x one bit toward the most-significant
\ bit, filling the vacated least-significant bit with zero.

	: 2* ( x -- x' ) dup + ;

\ https://forth-standard.org/standard/core/TwoDiv
\
\ x' is the result of shifting x1 one bit toward the least-significant
\ bit, leaving the most-significant bit unchanged.

	: 2/ ( x -- x' )
		dup 0< msb and	\ n signbitmask (0 or msb)
		swap 1 rshift	\ signbitmask (n>>1 logical)   (if your rshift is logical)
		or				\ arithmetic result
	;

\ https://forth-standard.org/standard/core/PlusStore
\
\ Add n | u to the single-cell number at a-addr.

	: +! ( n|u a-addr -- )
		tuck		( n a-addr -- a-addr n a-addr )
		@ + 		( a-addr n a-addr -- a-addr n' )
		swap ! 		( a-addr n' -- )
	;

\ https://forth-standard.org/standard/core/MAX
\
\ n3 is the greater of n1 and n2.

	: max ( n1 n2 -- n3 ) over 2dup > >r - r> and + ;

\ https://forth-standard.org/standard/core/MIN
\
\ n3 is the lesser of n1 and n2.

	: min ( n1 n2 -- n3 ) over 2dup < >r - r> and + ;
