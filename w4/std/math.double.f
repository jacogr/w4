require memory.f
require stack.f

\ https://forth-standard.org/standard/core/StoD
\
\ Convert the number n to the double-cell number d with the same numerical value.

	: S>D  ( n -- d ) dup 0< ;

\ https://forth-standard.org/standard/double/DToS
\
\ n is the equivalent of d. An ambiguous condition exists if d lies outside the range
\ of a signed single-cell number.

	: D>S ( lo hi -- n ) drop ;

\ https://forth-standard.org/standard/double/DPlus
\
\ Add d2 | ud2 to d1 | ud1, giving the sum d3 | ud3.

	: UM+ ( u1 u2 -- sum carry-flag )
		over >r + 	( u1 u2 -- sum ) ( r: -- u1 )
		dup r> u<	( sum -- sum carry ) ( r: u1 -- ) \ carry = sum u< u1
	;

	: D+ ( lo1 hi1 lo2 hi2 -- lo3 hi3 )
		>r swap >r	\ lo1 lo2 ( r: -- hi2 hi1 )
		um+ 		\ lo3 carry-flag
		1 and 		\ lo3 carry(0|1)
		r> r> + 	\ lo3 carry hiSum ( r: hi2 hi1 -- )
		swap + 		\ lo3 hi3
	;

\ https://forth-standard.org/standard/double/DNEGATE
\
\ d2 is the negation of d1.

	: DNEGATE ( lo hi -- lo' hi' )
		invert swap		( lo hi -- ~hi lo )
		invert swap		( ~hi lo -- ~lo ~hi )
		1. d+			( ~lo ~hi -- lo' hi' ) \ +1 as double
	;

\ https://forth-standard.org/standard/double/DMinus
\
\ subtract d2 from d1

	: UM- ( u1 u2 -- diff borrow-flag )
		2dup u< >r 	( u1 u2 -- u1 u2 ) ( r: -- borrow ) \ borrow? = (u1 < u2)
		- 			( u1 u2 -- diff ) \ diff = u1 - u2 (mod cell)
		r>			( diff -- diff borrow ) ( r: borrow -- )
	;

	: D- ( lo1 hi1 lo2 hi2 -- lo3 hi3 )
		>r swap >r 	( lo1 hi1 lo2 hi2 -- lo1 lo2 ) ( r: -- hi2 hi1 )
		um- 		( lo1 lo2 -- lo3 borrow )
		0<> 1 and 	( lo3 borrow -- lo3 borrow' )
		r> r> 		( lo3 borrow -- lo3 0|1 hi1 hi2 ) ( r: hi2 hi1 -- )
		- 			( lo3 borrow -- lo3 borrow hiDiff ) \ hiDiff = hi1 - hi2
		swap - 		( lo3 borrow hiDiff -- lo3 hi3 ) \ hi3 = hiDiff - borrow
	;

\ https://forth-standard.org/standard/double/DZeroEqual
\
\ true if d is zero

	: D0= ( lo hi -- flag )
		or 0=
	;

\ https://forth-standard.org/standard/double/DZeroLess
\
\ true if d is negative (sign bit set)

	: D0< ( lo hi -- flag )
		nip 0<
	;

\ https://forth-standard.org/standard/double/DEqual
\
\ flag is true if and only if xd1 is bit-for-bit the same as xd2.

	: D= ( lo1 hi1 lo2 hi2 -- flag )
		d- d0=
	;

\ https://forth-standard.org/standard/double/DLess
\
\ true if d1 < d2 (signed comparison)

	: D< ( lo1 hi1 lo2 hi2 -- flag )
		rot swap			( lo1 hi1 lo2 hi2 -- lo1 lo2 hi1 hi2 )
		2dup = if
			2drop u<		( lo1 lo2 hi1 hi2 -- f ) \ f = lo1 u< lo2
		else
			< 2nip			( lo1 lo2 hi2 hi2 -- f ) \ f = hi1 < hi2, drop lo1 lo2
		then
	;

\ https://forth-standard.org/standard/double/DUless
\
\ flag is true if and only if ud1 is less than ud2.

	: DU< ( lo1 hi1 lo2 hi2 -- flag )
		rot swap			( lo1 hi1 lo2 hi2 -- lo1 lo2 hi1 hi2 )
		2dup = if
			2drop u<        ( lo1 lo2 hi1 hi2 -- f ) \ f = lo1 u< lo2
		else
			u< 2nip			( lo1 lo2 hi1 hi2 -- f ) \ f = hi1 u< hi2
		then
	;

\ https://forth-standard.org/standard/double/DABS
\
\ ud is the absolute value of d.

	: DABS ( lo hi -- lo' hi' ) dup 0< if dnegate then ;

\ https://forth-standard.org/standard/core/UMDivMOD
\
\ Divide ud by u1, giving the quotient u3 and the remainder u2. All values and
\ arithmetic are unsigned. An ambiguous condition exists if u1 is zero or if
\ the quotient lies outside the range of a single-cell unsigned integer.

	: UM/MOD  ( lo hi u -- rem quot )
		1 swap 					( lo hi u -- lo hi 1 u )
		um*/mod 				( lo hi 1 u -- rem qlo qhi )
		\ enforce standard um/mod quotient range: qhi must be 0
		dup 0<> #-11 and throw 	( rem qlo qhi -- rem qlo qhi )  \ throw if qhi != 0
		drop 					( rem qlo qhi -- rem qlo )
	;

\ https://forth-standard.org/standard/core/UMTimes
\
\ Multiply u1 by u2, giving the unsigned double-cell product ud. All values and
\ arithmetic are unsigned.

	: UM* ( u1 u2 -- ud )
		0 swap 1	( u1 u2 -- lo 0 u2 1 )
		um*/mod		( lo 0 u2 1 -- rem qlo qhi )
		rot drop	( rem qlo qhi -- qlo qhi )
	;

\ https://forth-standard.org/standard/core/SMDivREM
\
\ Divide d1 by n1, giving the symmetric quotient n3 and the remainder n2.
\ Input and output stack arguments are signed. An ambiguous condition exists
\ if n1 is zero or if the quotient lies outside the range of a single-cell
\ signed integer.

	: SM/REM  ( lo hi n -- rem quot )
		1 swap m*/mod			( lo hi n -- rem qlo qhi )
		\ range check: qhi must equal sign-extension of qlo
		>r						( rem qlo qhi -- rem qlo ) ( r: -- qhi )
		dup 0<					( rem qlo -- req qlo signq )
		r>						( rem qlo signq -- rem qlo signq qhi )
		<> #-11 and throw    	( rem qlo signq qhi -- rem qlo )
	;

\ https://forth-standard.org/standard/core/FMDivMOD
\
\ Divide d1 by n1, giving the floored quotient n3 and the remainder n2. Input
\ and output stack arguments are signed. An ambiguous condition exists if n1
\ is zero or if the quotient lies outside the range of a single-cell signed
\ integer.

	: FM/MOD ( lo hi n -- r q )
		dup >r				( lo hi n -- lo hi n ) ( r: -- n )
		over 0< >r			( lo hi n -- lo hi n ) ( r: n -- n signD ) \ signD = hi sign
		sm/rem				( lo hi n --  r q )

		over 0<>			( r q -- r q nz ) \ nz = r <> 0
		r>					( r q nz -- r q nz signD ) ( r: n signD -- n )
		r@ 0< xor			( r q nz signD -- r q nz mismatch? ) ( r: n -- n )
		and 				( r q nz mismatch? -- r q adjust? ) \ adjust? = nz & mismatch?

		if
			swap r> +		( r q -- q r+n ) ( r: n -- )
			swap 1-			( q r+ n -- r+n q-1 )
		else
			r-drop			( r q -- r q ) ( r: n -- )
		then
	;

\ https://forth-standard.org/standard/double/MPlus
\
\ Add n to d1 | ud1, giving the sum d2 | ud2.

	: M+ ( d n -- d' ) s>d d+ ;

\ https://forth-standard.org/standard/double/MTimesDiv
\
\ Multiply d1 by n1 producing the triple-cell intermediate result t. Divide t
\ by +n2 giving the double-cell quotient d2. An ambiguous condition exists if
\ +n2 is zero or negative, or the quotient lies outside of the range of a
\ double-precision signed integer.

	: M*/  ( lo hi n1 +n2 -- lo' hi' )
		dup 0= #-10 and throw
		dup 0< #-11 and throw

		m*/mod				( lo hi n1 +n2 -- rem qlo qhi )
		rot drop			( rem qlo qhi -- qlo qhi )
	;

\ https://forth-standard.org/standard/core/MTimes
\
\ d is the signed product of n1 times n2.

	: M*  ( n1 n2 -- lo hi )
		s>d 		( n1 n2 -- n1 lo hi )     \ d1 = n2 as double
		rot			( n1 lo hi -- lo hi n1 )  \ mul = n1
		1 m*/mod 	( lo hi n1 1 -- rem qlo qhi )
		rot drop 	( rem qlo qhi -- qlo qhi )
	;

\ https://forth-standard.org/standard/double/DTwoTimes
\
\ xd2 is the result of shifting xd1 one bit toward the most-significant bit,
\ filling the vacated least-significant bit with zero.

	: D2* ( lo hi -- lo' hi' )
		2dup d+
	;

\ https://forth-standard.org/standard/double/DTwoDiv
\
\ xd2 is the result of shifting xd1 one bit toward the least-significant bit,
\ leaving the most-significant bit unchanged.

	: ARSHIFT1 ( n -- n' )
		dup 0< 			\ n flag
		msb 0 select 	\ n mask
		swap 1 rshift 	\ mask n>>1
		or
	;

	: D2/ ( lo hi -- lo' hi' )
		dup 1 and 			\ lo hi hibit
		>r
		arshift1			\ lo hi'
		swap 1 rshift		\ hi' lo>>1
		r> 31 lshift or		\ hi' lo'
		swap				\ lo' hi'
	;

\ https://forth-standard.org/standard/double/DMax
\
\ d3 is the greater of d1 and d2.

	: DMAX ( d1 d2 -- d3 )
		2over 2over d< if 2swap then 2drop
	;

\ https://forth-standard.org/standard/double/DMin
\
\ d3 is the lesser of d1 and d2.

	: DMIN ( d1 d2 -- d3 )
		2over 2over d< 0= if 2swap then 2drop
	;

\ Non-standard extension to um/mod to work with unsigned
\ numbers, without restrictions

	: U/MOD  ( u d -- urem uquot )
		0 swap		( u d -- ulo 0 d )
		um/mod		( ulo 0 d -- ur uq )
	;

	: UD/MOD ( lo hi u -- rem qlo qhi )
		>r 			( lo hi u -- lo hi ) ( r: -- u )
		r@ u/mod 	( lo hi u -- lo rem qhi )
		r> 			( lo rem qhi -- lo rem qhi u ) ( r: u -- )
		swap 		( lo rem qhi u -- lo rem u qhi )
		>r 			( lo rem u qhi -- lo rem u ) ( r: -- qhi )
		um/mod 		( lo rem u -- rem qlo ) \ LEGAL: rem < u
		r> 			( req qlo -- rem qlo qhi ) ( r: qhi -- )
	;

\ https://forth-standard.org/standard/double/TwoCONSTANT
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below.
\
\ At runtime: Place cell pair x1 x2 on the stack.

	: 2CONSTANT ( x1 x2 "name" -- )
		create 2,
 		does> 2@
	;

\ https://forth-standard.org/standard/double/TwoVARIABLE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below. Reserve
\ two consecutive cells of data space.
\
\ At runtime: a-addr is the address of the first (lowest address) cell of
\ two consecutive cells in data space reserved by 2VARIABLE when it defined
\ name. A program is responsible for initializing the contents.

	: 2VARIABLE ( "name" -- )
		create  0 ,  0 ,	\ reserve 2 cells, init to 0. (lo=0 hi=0)
  		does>
	;

\ https://forth-standard.org/standard/double/TwoLITERAL
\
\ Append the run-time semantics below to the current definition.
\
\ At run time, place cell pair x1 x2 on the stack.

	: 2LITERAL ( x1 x2 -- )
		swap
		lit, lit,
	; immediate
