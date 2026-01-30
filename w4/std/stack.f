m4_require_w4(`std/stack-base.f')
m4_require_w4(`std/stack-control.f')
m4_require_w4(`std/stack-cs.f')
m4_require_w4(`std/stack-rs.f')
m4_require_w4(`std/stack-ptr.f')

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
