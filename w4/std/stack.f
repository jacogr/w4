m4_require_w4(`std/constants.f')
m4_require_w4(`std/logic.f')
m4_require_w4(`std/stack-ptr.f')

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

m4_require_w4(`std/stack-cs.f')
m4_require_w4(`std/stack-rs.f')

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
