m4_require(<!std/compile.f!>)
m4_require(<!std/constants.f!>)
m4_require(<!std/memory.f!>)
m4_require(<!std/parse.f!>)
m4_require(<!std/string-format.f!>)

m4_require(<!ext/is.f!>)

\ https://forth-standard.org/standard/core/ABORT
\
\ Empty the data stack and perform the function of QUIT, which includes
\ emptying the return stack, without displaying a message.

	: ABORT #-1 throw ;

\ https://forth-standard.org/standard/exception/ABORTq
\
\ Parse ccc delimited by a " (double-quote). Append the run-time semantics
\ given below to the current definition.
\
\ At runtime: Remove x1 from the stack. If any bit of x1 is not zero, perform
\ the function of -2 THROW, displaying ccc if there is no exception frame on
\ the exception stack.

	\ TODO(stage2): ABORT" disabled for src->wat bootstrap path.
	\ Re-enable once postpone+s" handling is fully stable in generator.
	\ : ABORT" ( "ccc<quote>" -- )
	\ 	postpone if
	\ 		postpone s"
	\ 		postpone type
	\ 		$-2 lit,
	\ 		postpone throw
	\ 	postpone then
	\ ; immediate

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

	: (to-2value) ( x1 x2 a-addr -- ) 2! ;

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
		\ get xt
		'							( x "name" -- x... xt )

		\ check for local
		dup >flags @				( x... xt -- x... xt flags )
		(flg-xt-local) is-flag? if 	( x... xt flags -- x... xt )
			(xt>value@)				( x... xt -- x... idx )
			state @ if
				lit,
				postpone (to-local)
			else (to-local) then
		else
			\ assume via create
			>body					( x... xt -- x... a-addr )
			dup @					( x... a-addr -- x... a-addr xt )
			swap cell+				( x... a-addr xt -- x... xt a-addr' )
			state @ if
				lit, lit,			\ compile a-addr, xt (runtime: xt, a-addr )
				postpone execute
			else swap execute then
		then
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

\ https://forth-standard.org/standard/tools/SYNONYM
\
\ For both strings skip leading space delimiters. Parse newname and oldname
\ delimited by a space. Create a definition for newname with the semantics
\ defined below. Newname may be the same as oldname; when looking up oldname,
\ newname shall not be found.
\
\ An ambiguous conditions exists if oldname can not be found or IMMEDIATE is
\ applied to newname.

		: SYNONYM ( "newname" "oldname" -- )
			create
				hide ' , reveal
			does>
				@ state @ 0= over is-xt-immediate? or
				['] execute ['] compile,
				select
				execute
		; immediate

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
