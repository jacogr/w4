m4_require_w4(`std/stack-ptr.f')

\ unconditional branch to destination
\ (Standard in older versions of ANS Forth, not in 2012)

	: BRANCH ( dest -- ) r! ;

\ https://forth-standard.org/standard/core/toR
\
\ Move x to the return stack.

	: >R ( x -- r:x )
		r@ swap		\ Swap the input & address
		r!			\ Write input to location
		branch
	;

\ https://forth-standard.org/standard/core/TwotoR
\
\ Transfer cell pair x1 x2 to the return stack. Semantically
\ equivalent to SWAP >R >R.

	: (2>radd) ( ret x2 -- ) ( r: -- x1 x2 )
		r!				( ret x2 -- ret ) ( r: x1 ret-2>r -- x1 x2 )
		branch
	;

	: 2>R ( x1 x2 -- ) ( R: -- x1 x2 )
		swap r@			( x1 x2 -- x2 x1 ret ) ( r: ret -- ret )
		swap r!			( x2 x1 ret -- x2 ret ) ( r: ret -- x1 )
		swap (2>radd)	( x2 ret -- )
	;

\ https://forth-standard.org/proposals/standardize-the-well-known-rdrop#contribution-417
\
\ Drop the top-most return stack value

	: (r-drop) ( -- )
		\ -6 return stack underflow
		r-depth 3 < #-6 and throw	\ call into r-drop & this

		r-1@ r-2!					\ slide caller’s return-to down
		r-depth 2 - (rs^) !			\ drop one slot under it
	;

	: R-DROP ( -- ) (r-drop) ;

\ https://forth-standard.org/standard/core/Rfrom
\
\ Move x from the return stack to the data stack.

	: R> ( R:x -- x )
		r-1@		\ fetch value under caller’s return-to
		(r-drop)
	;

\ https://forth-standard.org/standard/core/TwoRfrom
\
\ Transfer cell pair x1 x2 from the return stack. Semantically
\ equivalent to R> R> SWAP.

	: (r-2drop) ( -- )
		\ -6 return stack underflow
		r-depth 4 < #-6 and throw	\ call into r-drop & this

		r-1@ r-3!					\ slide caller’s return-to down
		r-depth 3 - (rs^) !			\ drop two slots under it
	;

	: 2R> ( -- x1 x2 ) ( R: x1 x2 -- )
		r-2@ r-1@
		(r-2drop)
	;

\ https://forth-standard.org/standard/core/TwoRFetch
\
\ Copy cell pair x1 x2 from the return stack. Semantically
\ equivalent to R> R> 2DUP >R >R SWAP.

	: 2R@ ( r: x y ) ( -- x y )
		r-2@ r-1@
	;
