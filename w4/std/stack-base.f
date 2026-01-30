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
