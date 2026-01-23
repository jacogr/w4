require logic.f
require loops.f
require stack.f

\ https://forth-standard.org/standard/core/ABS
\
\ u is the absolute value of n.

	: ABS ( n -- u ) dup 0< if negate then ;

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

	: MAX ( n1 n2 -- n3 ) over 2dup > >r - r> and + ;

\ https://forth-standard.org/standard/core/MIN
\
\ n3 is the lesser of n1 and n2.

	: MIN ( n1 n2 -- n3 ) over 2dup < >r - r> and + ;

\ mid-point require: *, /, & /mod is built on top of double operations

require math.double.f

\ https://forth-standard.org/standard/core/Times
\
\ Multiply n1 | u1 by n2 | u2 giving the product n3 | u3.

	: * ( n1 n2 -- n3 ) m* drop ;

\ https://forth-standard.org/standard/core/DivMOD
\
\ Divide n1 by n2, giving the single-cell remainder n3 and the single-cell
\ quotient n4. An ambiguous condition exists if n2 is zero. If n1 and n2
\ differ in sign, the implementation-defined result returned will be the
\ same as that returned by either the phrase >R S>D R> FM/MOD or the
\ phrase >R S>D R> SM/REM.

	\ As per C
	: /MOD ( n1 n2 -- q r ) >r s>d r> sm/rem ;

\ https://forth-standard.org/standard/core/TimesDiv
\
\ Multiply n1 by n2 producing the intermediate double-cell result d. Divide d
\ by n3 giving the single-cell quotient n4. An ambiguous condition exists if
\ n3 is zero or if the quotient n4 lies outside the range of a signed number.
\ If d and n3 differ in sign, the  implementation-defined result returned will
\ be the same as that returned  by either the phrase >R M* R> FM/MOD SWAP DROP
\ or the phrase >R M* R> SM/REM SWAP DROP.

	: */ ( n1 n2 n3 -- n4 )
		>r m* r> sm/rem swap drop
	;

\ https://forth-standard.org/standard/core/TimesDivMOD
\
\ Multiply n1 by n2 producing the intermediate double-cell result d.
\ Divide d by n3 producing the single-cell remainder n4 and the single-cell
\ quotient n5. An ambiguous condition exists if n3 is zero, or if the quotient
\ n5 lies outside the range of a single-cell signed integer. If d and n3
\ differ in sign, the implementation-defined result returned will be the same \
\ as that returned by either the phrase >R M* R> FM/MOD or the phrase >R M* R> SM/REM.

	: */MOD ( n1 n2 n3 -- r q )
		>r m* r> sm/rem
	;

\ https://forth-standard.org/standard/core/Div
\
\ Divide n1 by n2, giving the single-cell quotient n3. An ambiguous condition
\ exists if n2 is zero. If n1 and n2 differ in sign, the implementation-defined
\ result returned will be the same as that returned by either the phrase
\ >R S>D R> FM/MOD SWAP DROP or the phrase >R S>D R> SM/REM SWAP DROP.

	: / ( q r - r ) /mod nip ;

	: U/ u/mod nip ;

	: UM/ um/mod nip ;

\ https://forth-standard.org/standard/core/MOD
\
\ Divide n1 by n2, giving the single-cell remainder n3. An ambiguous condition
\ exists if n2 is zero. If n1 and n2 differ in sign, the implementation-defined
\ result returned will be the same as that returned by either the phrase
\ >R S>D R> FM/MOD DROP or the phrase >R S>D R> SM/REM DROP.

	: MOD ( q r - q ) /mod drop ;
