require loops.f
require stack.f

\ https://forth-standard.org/standard/core/qDUP
\
\ Duplicate x if it is non-zero.

	: ?dup dup if dup then ;

\ https://forth-standard.org/standard/core/ROLL
\
\ Remove u. Rotate u+1 items on the top of the stack. An ambiguous condition
\ exists if there are less than u+2 items on the stack before ROLL is executed.

	: roll ( x0 i*x u.i -- i*x x0 )
		dup 0= if
			drop
			exit
		then

		swap >r
		1- recurse
		r> swap
	;

