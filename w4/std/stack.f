require w4/std/logic.f
require w4/std/stack.ptr.f

\ https://forth-standard.org/standard/core/CELLPlus

	: cell+ ( a-addr -- a-addr' ) 1 cells + ;

\ https://forth-standard.org/standard/core/NIP

	: nip ( x y -- y ) swap drop ;

\ https://forth-standard.org/standard/core/PICK

	: pick 1+ cells sp@ swap - @ ;

\ https://forth-standard.org/standard/core/TUCK

	: tuck ( x y -- y x y ) swap over ;

\ https://forth-standard.org/standard/core/TwoDUP

	: 2dup ( x y -- x y x y ) over over ;

\ https://forth-standard.org/standard/core/TwoOVER

	: 2over ( x y -- x y x y ) sp-3@ sp-3@ ;

\ https://forth-standard.org/standard/core/TwoSWAP

	: 2swap ( 1 2 3 4 -- 3 4 1 2 )
		sp-1@ sp-1@		( a b c d -- a b c d c d )
		sp-5@ sp-5@ 	( a b c d c d -- a b c d c d a b )
		sp-4! sp-4! 	( a b c d c d a b -- a b a b c d )
		sp-4! sp-4! 	( a b a b c d -- c d a b )
	;

\ https://forth-standard.org/standard/core/TwoDROP

	: 2drop ( x y -- ) drop drop ;

\ https://forth-standard.org/standard/core/ROT

	: 3dup ( x y z -- x y z x y z ) sp-2@ sp-2@ sp-2@ ;

	: rot ( x y z -- y z x )
		3dup
		sp-4!	( x y z x y z -- x z z x y )
		sp-4!	( x z z x y -- y z z x )
		sp-1!	( y z z x -- y z x )
	;

	: -rot ( x y z -- z x y )
		3dup
		sp-5!	( x y z x y z -- x z z x y )
		sp-2!	( x z z x y -- y z z x )
		sp-2!	( y z z x -- y z x )
	;

\ Drop a values from the control stack

	: cs-drop ( c: x -- ) cs-depth dup 0= #-7 and throw 1- (cp^) ! ;

\ Move value to control stack

	: >cs ( x -- ) ( c: -- x )
		cs-depth 1+
		dup $2f = #-52 and throw
		(cp^) !			\ count++
		cs-depth cells
		(cp^) + !		\ store value
	;

\ Move value from control stack

	: cs> ( -- x ) ( c: x -- ) cs@ @ cs-drop ;

\ Duplicates a value on the control stack

	: cs-dup cs@ @ >cs ;

\ as per the sp version

	: cs-swap ( c: x y -- y x )
		cs-1@ cs-0@	( -- y x )
		cs-1! cs-0!
	;

\ https://forth-standard.org/standard/tools/CS-PICK

	: cs-pick ( n -- x ) (cs@-) @ ;

\ unconditional branch to value on cs
\ (Standard in older versions of ANS Forth, not in 2012)

	: branch ( dest -- ) r! ;

\ https://forth-standard.org/standard/core/toR

	: >r ( x -- r:x )
		r@ swap		\ Swap the input & address
		r!			\ Write input to location
		branch
	;

\ https://forth-standard.org/standard/core/TwotoR

	: (2>radd) ( ret x2 -- ) ( r: -- x1 x2 )
		r!			( ret x2 -- ret ) ( r: x1 -- x1 x2 )
		branch
	;

	: 2>r ( x1 x2 -- ) ( R: -- x1 x2 )
		r@ -rot swap	( x1 x2 -- ret x2 x1 )
		r!				( ret x2 x1 -- ret x2 ) ( r: -- x1 )
		(2>radd)
	;

\ https://forth-standard.org/proposals/standardize-the-well-known-rdrop#contribution-417

	: (r-drop) ( -- )
		r-depth 3 < #-6 and throw	\ call into r-drop & this
		r-1@ r-2!					\ slide caller’s return-to down
		r-depth 2 - (rp^) !			\ drop one slot under it
	;

	: r-drop ( -- ) (r-drop) ;

\ https://forth-standard.org/standard/core/Rfrom

	: r> ( R:x -- x )
		r-1@		\ fetch value under caller’s return-to
		(r-drop)
	;

\ https://forth-standard.org/standard/core/TwoRfrom

	: (r-2drop) ( -- )
		r-depth 4 < #-6 and throw	\ call into r-drop & this
		r-1@ r-3!					\ slide caller’s return-to down
		r-depth 3 - (rp^) !			\ drop two slots under it
	;

	: 2r> ( -- x1 x2 ) ( R: x1 x2 -- )
		r-2@ r-1@
		(r-2drop)
	;

\ https://forth-standard.org/standard/core/TwoRFetch

	: 2r@ ( r: x y ) ( -- x y )
		r-2@ r-1@
	;

\ https://forth-standard.org/standard/core/ROLL
\ https://forth-standard.org/standard/tools/CS-ROLL

	\ dup 0= if drop exit then  swap >r 1- recurse r> swap
	\ : roll ( xn-1 ... x0 i -- xn-1 ... xi-1 xi+1 ... x0 xi )
    \ 	?dup 0= ?exit swap >r 1- recurse r> swap
    \ ;
