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

	: (to-value)  ( x a-addr -- ) ! ;

	: VALUE ( x "name" -- )
		create ['] (to-value) ,  ,	\ store executor & value
		does> cell+ @
	;

\ https://forth-standard.org/standard/double/TwoVALUE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below, with an
\ initial value of x1 x2.
\
\ Place cell pair x1 x2 on the stack. The value of x1 x2 is that given when
\ name was created, until the phrase "x1 x2 TO name" is executed, causing a
\ new cell pair x1 x2 to be assigned to name.

	: (to-2value) ( x1 x2 a-addr -- )  2! ;

	: 2VALUE ( x1 x2 "name" -- )
		create ['] (to-2value) , 2,	\ store executor & values
		does> cell+ 2@
	;

\ https://forth-standard.org/standard/core/TO
\
\ Interpretation: Skip leading spaces and parse name delimited by a space.
\ Perform the "TO name run-time" semantics given in the definition for the
\ defining word of name. An ambiguous condition exists if name was not defined
\ by a word with "TO name run-time" semantics.

	: TO ( x "name" -- )
		' >body				( x "name" -- x... a-addr )
		dup @				( x... a-addr -- x... a-addr xt )
		swap cell+			( x... a-addr xt -- x... xt a-addr' )
		state @ if
			lit, lit,		\ compile a-addr, xt (runtime: xt, a-addr )
			postpone execute
		else swap execute then
	; immediate

\ https://forth-standard.org/standard/core/DEFER
\
\ Skip leading space delimiters. Parse name delimited by a space. Create
\ a definition for name with the execution semantics defined below.
\
\ At runtime: Execute the xt that name is set to execute. An ambiguous
\ condition exists if name has not been set to execute an xt.

	: DEFER ( "name" -- )
		create ['] abort , 			\ initial action
		does>  ( xt -- ) @ execute
	;

\ https://forth-standard.org/standard/core/DEFERFetch
\
\ xt2 is the execution token xt1 is set to execute. An ambiguous condition
\ exists if xt1 is not the execution token of a word defined by DEFER, or
\ if xt1 has not been set to execute an xt.

	: DEFER@ ( xt1 -- xt2 ) >body @ ;

\ https://forth-standard.org/standard/core/DEFERStore
\
\ Set the word xt1 to execute xt2. An ambiguous condition exists if xt1 is
\ not for a word defined by DEFER.

	: DEFER! ( xt2 xt1 -- ) >body ! ;

\ https://forth-standard.org/standard/core/IS
\
\ Skip leading spaces and parse name delimited by a space. Set name to execute xt.
\ An ambiguous condition exists if name was not defined by DEFER.

	: IS ( "name" -- )
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

	: ACTION-OF ( "name" -- xt2 )
		state @ if
			postpone [']
			postpone defer@
		else ' defer@ then
	; immediate
