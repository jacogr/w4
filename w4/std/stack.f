m4_require_w4(`std/stack-base.f')
m4_require_w4(`std/stack-ptr.f')
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
