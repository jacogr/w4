require logic.f
require stack.ptr.f

\ https://forth-standard.org/standard/core/CELLPlus
\
\ Add the size in address units of a cell to a-addr1, giving a-addr2.

	1 cells constant CELL

	: CELL+ ( a-addr -- a-addr' ) cell + ;

\ https://forth-standard.org/standard/core/NIP
\
\ Drop the first item below the top of stack.

	: NIP ( x y -- y ) sp-1! ;

	: 2NIP ( x y z -- z ) nip nip ;

	: 3NIP ( a x y z -- z ) nip nip nip ;

\ https://forth-standard.org/standard/core/PICK
\
\ Copy the xu to the top of the stack. An ambiguous condition exists if there
\ are less than u+2 items on the stack before PICK is executed.

	: PICK ( xu...x1 x0 u -- xu...x1 x0 xu ) 1+ cells sp@ swap - @ ;

\ https://forth-standard.org/standard/core/TUCK
\
\ Copy the first (top) stack item below the second stack item.

	: TUCK ( x y -- y x y ) swap over ;

\ https://forth-standard.org/standard/core/TwoDUP
\
\ Duplicate cell pair

	: 2DUP ( x y -- x y x y ) sp-1@ sp-1@ ;

	: 3DUP ( x y z -- x y z x y z ) sp-2@ sp-2@ sp-2@ ;

	: 4DUP ( a b c d -- a b c d a b c d ) sp-3@ sp-3@ sp-3@ sp-3@ ;

\ https://forth-standard.org/standard/core/TwoOVER
\
\ Copy cell pair x1 y2 to the top of the stack.

	: 2OVER ( x1 y1 x2 y2 -- x1 y1 x2 y2 x1 y1 ) sp-3@ sp-3@ ;

\ https://forth-standard.org/standard/core/TwoSWAP
\
\ Exchange the top two cell pairs.

	: 2SWAP ( a b c d -- c d a b )
		sp-1@ sp-1@		( a b c d -- a b c d c d )
		sp-5@ sp-5@ 	( a b c d c d -- a b c d c d a b )
		sp-4! sp-4! 	( a b c d c d a b -- a b a b c d )
		sp-4! sp-4! 	( a b a b c d -- c d a b )
	;

\ https://forth-standard.org/standard/core/TwoDROP
\
\ Drop cell pair x y from the stack.

	: 2DROP ( x y -- ) drop drop ;

	: 3DROP ( x y -- ) drop drop drop ;

	: 4DROP ( x y -- ) drop drop drop drop ;

\ https://forth-standard.org/standard/core/ROT
\
\ Rotate the top three stack entries. (-rot is the reverse, or rot rot)

	: ROT ( x y z -- y z x )
		3dup
		sp-4!	( x y z x y z -- x z z x y )
		sp-4!	( x z z x y -- y z z x )
		sp-1!	( y z z x -- y z x )
	;

	: -ROT ( x y z -- z x y )
		3dup
		sp-5!	( x y z x y z -- x z z x y )
		sp-2!	( x z z x y -- y z z x )
		sp-2!	( y z z x -- y z x )
	;

\ Drop a values from the control stack

	: CS-DROP ( c: x -- ) cs-depth dup 0= #-7 and throw 1- (cs^) ! ;

\ Move value to control stack

	: >CS ( x -- ) ( c: -- x )
		cs-depth 1+
		dup $2f = #-52 and throw
		(cs^) !			\ count++
		cs-depth cells
		(cs^) + !		\ store value
	;

\ Move value from control stack

	: CS> ( -- x ) ( c: x -- ) cs@ @ cs-drop ;

\ Duplicates a value on the control stack

	: CS-DUP cs@ @ >cs ;

\ as per the sp version

	: CS-SWAP ( c: x y -- y x )
		cs-1@ cs-0@	( -- x y )
		cs-1! cs-0!	( x y -- )
	;

\ https://forth-standard.org/standard/tools/CS-PICK
\
\ Remove u. Copy destu to the top of the control-flow stack. An ambiguous
\ condition exists if there are less than u+1 items, each of which shall be
\ an orig or dest, on the control-flow stack before CS-PICK is executed.

	: CS-PICK ( n -- x ) (cs@-) @ ;

\ unconditional branch to value on cs
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
		r!			( ret x2 -- ret ) ( r: x1 -- x1 x2 )
		branch
	;

	: 2>R ( x1 x2 -- ) ( R: -- x1 x2 )
		r@ -rot swap	( x1 x2 -- ret x2 x1 )
		r!				( ret x2 x1 -- ret x2 ) ( r: -- x1 )
		(2>radd)
	;

\ https://forth-standard.org/proposals/standardize-the-well-known-rdrop#contribution-417
\
\ Drop the top-most return stack value

	: (r-drop) ( -- )
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

\ https://forth-standard.org/standard/core-ext/TwoROT
\
\ Rotate the top three cell pairs on the stack bringing cell pair
\ x1 x2 to the top of the stack.

	: 2ROT ( x1 x2 x3 x4 x5 x6 -- x3 x4 x5 x6 x1 x2 )
		>r >r	\ x1 x2 x3 x4       ( r: -- x6 x5 )
		2swap	\ x3 x4 x1 x2
		r> r>	\ x3 x4 x1 x2 x5 x6 ( r: x6 x5 -- )
		2swap	\ x3 x4 x5 x6 x1 x2
	;
