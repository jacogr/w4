require memory.f

\ https://forth-standard.org/standard/core/VALUE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below, with an
\ initial value equal to x.
\
\ At runtime: Place x on the stack. The value of x is that given when name
\ was created, until the phrase x TO name is executed, causing a new value
\ of x to be assigned to name.

	: value ( x "name" -- ) create , does> @ ;

\ https://forth-standard.org/standard/double/TwoVALUE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below, with an
\ initial value of x1 x2.
\
\ Place cell pair x1 x2 on the stack. The value of x1 x2 is that given when
\ name was created, until the phrase "x1 x2 TO name" is executed, causing a
\ new cell pair x1 x2 to be assigned to name.

	: 2value ( x1 x2 "name" -- ) create 2, does> 2@ ;

\ https://forth-standard.org/standard/core/TO
\
\ Interpretation: Skip leading spaces and parse name delimited by a space.
\ Perform the "TO name run-time" semantics given in the definition for the
\ defining word of name. An ambiguous condition exists if name was not defined
\ by a word with "TO name run-time" semantics.

	: (to)  ( x a-addr -- ) ! ;

	: to ( x "name" -- )
		' >body				( x a-addr )
		state @ if
			lit,			\ compile addr, x to be supplied at runtime
			postpone (to)	\ execute helper
		else (to) then		\ execute helper on interpret
	; immediate

\ Non-standard, well-known. Same as to but with +! semantics

	: (+to) ( x a-addr -- ) +! ;

	: +to ( x "name" -- )
		' >body 			( x a-addr )
		state @ if lit,	postpone (+to) else (+to) then
	; immediate

\ Non-standard, well-known. As per the single-cell version, same semantics.

	: (2to)  ( x1 x2 a-addr -- ) 2! ;

	: 2to ( x1 x2 "name" -- )
		' >body 			( x1 x2 a-addr )
		state @ if lit,	postpone (2to) else (2to) then
	; immediate

\ Non-standard, well-known. As per the single-cell version, same semantics.

	: (2+to) ( x1 x2 a-addr -- )
		>r 		( x1 x2 )
		r@ 2@ 	( x1 x2 y1 y2 )
		d+ 		( z1 z2 )
		r> 2!
	;

	: 2+to ( x1 x2 "name" -- )
		' >body 			( x1 x2 a-addr )
		state @ if lit, postpone (2+to) else (2+to) then
	; immediate

\ https://forth-standard.org/standard/core/DEFER
\
\ Skip leading space delimiters. Parse name delimited by a space. Create
\ a definition for name with the execution semantics defined below.
\
\ At runtime: Execute the xt that name is set to execute. An ambiguous
\ condition exists if name has not been set to execute an xt.

	: defer ( "name" -- )
		create ['] abort , 			\ initial action
		does>  ( xt -- ) @ execute
	;

\ https://forth-standard.org/standard/core/DEFERFetch
\
\ xt2 is the execution token xt1 is set to execute. An ambiguous condition
\ exists if xt1 is not the execution token of a word defined by DEFER, or
\ if xt1 has not been set to execute an xt.

	: defer@ ( xt1 -- xt2 ) >body @ ;

\ https://forth-standard.org/standard/core/DEFERStore
\
\ Set the word xt1 to execute xt2. An ambiguous condition exists if xt1 is
\ not for a word defined by DEFER.

	: defer! ( xt2 xt1 -- ) >body ! ;

\ https://forth-standard.org/standard/core/IS
\
\ Skip leading spaces and parse name delimited by a space. Set name to execute xt.
\ An ambiguous condition exists if name was not defined by DEFER.

	: is ( "name" -- )
		state @ if
			postpone [']
			postpone defer!
		else ' defer! then
	; immediate

\ https://forth-standard.org/standard/core/ACTION-OF
\
\ Skip leading spaces and parse name delimited by a space. xt is the execution
\ token that name is set to execute. An ambiguous condition exists if name was
\ not defined by DEFER, or if the name has not been set to execute an xt.

	: action-of ( "name" -- xt2 )
		state @ if
			postpone [']
			postpone defer@
		else ' defer@ then
	; immediate
