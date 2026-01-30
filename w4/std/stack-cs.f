m4_require_w4(`std/stack-ptr.f')

\ Drop a values from the control stack

	: CS-DROP ( c: x -- )
		cs-depth 				( -- n )

		\ -7 do-loops nested too deeply during execution
		dup 0= #-7 and throw	( n -- n )

		1- (cs^) !				( n -- )
	;

\ Move value to control stack

	: >CS ( x -- ) ( c: -- x )
		cs-depth 1+

		\ -52 control-flow stack overflow
		dup (env-stackmax#) = #-52 and throw

		(cs^) !			\ count++
		cs-depth cells
		(cs^) + !		\ store value
	;

	: 2>CS ( a b -- ) ( c: -- a b ) swap >cs >cs ;

\ Move value from control stack

	: CS> ( -- x ) ( c: x -- ) cs@ @ cs-drop ;

	: 2CS> ( -- a b ) ( c: a b -- ) cs> cs> swap ;

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

	: CS-PICK ( n -- x ) (cs^-n) @ ;
