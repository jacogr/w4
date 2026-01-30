m4_require_w4(`std/compile.f')
m4_require_w4(`std/control.f')
m4_require_w4(`std/locals.f')
m4_require_w4(`std/memory.f')

\ https://forth-standard.org/standard/core/QUIT
\ https://forth-standard.org/standard/usage#usage:command
\
\ Upon start-up, a system shall be able to interpret, as described by
\ 6.1.2050 QUIT, Forth source code received interactively from a user input
\ device.
\
\ Such interactive systems usually furnish a "prompt" indicating that they
\ have accepted a user request and acted on it. The implementation-defined
\ Forth prompt should contain the word "OK" in some combination of upper or
\ lower case.
\
\ Text interpretation (see 6.1.1360 EVALUATE and 6.1.2050 QUIT) shall repeat
\ the following steps until either the parse area is empty or an ambiguous
\ condition exists:
\
\ Skip leading spaces and parse a name (see 3.4.1);
\
\ Search the dictionary name space (see 3.4.2). If a definition name matching
\ the string is found:
\
\ if interpreting, perform the interpretation semantics of the definition
\ (see 3.4.3.2), and continue at a).
\
\ if compiling, perform the compilation semantics of the definition (see 3.4.3.3),
\ and continue at a).
\
\ If a definition name matching the string is not found, attempt to convert the
\ string to a number (see 3.4.1.3). If successful:
\
\ if interpreting, place the number on the data stack, and continue at a);
\
\ if compiling, compile code that when executed will place the number on the stack
\ (see 6.1.1780 LITERAL), and continue at a);
\
\ If unsuccessful, an ambiguous condition exists (see 3.4.4).

	: (interpret-number-conv) ( c-addr u -- n f )
		false 1 base 0
		{: str len isd? mul obase nbase :}	( c-addr u -- )

		\ extract last char (double indicator)
		len 1- str + c@						( -- char )

		\ char = '.'? (double value)
		'.' = if
			true to isd?
			len 1- to len					\ len = len -1
		then

		\ extract negative/base char
		str c@								( -- char )

		dup '-' = if						( char -- char )
			drop							( char -- )
			-1 to mul
			len 1- to len
			str 1+ to str
		else
			\ try to extract the base
			dup '$' <> if					( char -- char )
				dup '#' <> if				( char -- char )
					'%' = if #02 to nbase then
				else drop $0a to nbase then
			else drop $10 to nbase then

			\ have a new base?
			nbase if
				len 1- to len
				str 1+ to str

				str c@							( -- char )

				\ handle negative case
				'-' if
					-1 to mul
					len 1- to len
					str 1+ to str
				then
			then
		then

		\ ensure valid length
		len 0> if
			\ set base
			nbase if nbase base ! then

			\ convert
			0 0 str len >number					( -- lo hi c-addr u )

			\ reset base
			nbase if obase base ! then

			nip 0= if							( lo hi c-addr u -- lo hi )
				0= if							( lo hi -- lo )
					mul *						( lo -- n )
					isd? if -1 else 1 then 		( n -- n f )
				else drop 0 0 then				( lo -- 0 0 )
			else 2drop 0 0 then					( lo hi -- 0 0 )
		else 0 0 then							( -- 0 0 )
	;

	: (interpret-number) ( c-addr u -- )
		(interpret-number-conv)					( c-addr u -- n f )

		\ f <> 1? (number converted)
		dup if
			\ compiling?						( n f -- n f )
			state @ if
				(flg-xt-lit) swap				( nf -- n xtf f )

				-1 = if (flg-is-var) or then	( n xtf -- n xtf' )

				(new-xt)						( n xtf -- xt )
				compile,						( xt -- )
			else -1 = if 0 then then			( n f -- n ) \ hi = 0 if double
		else #-13 and throw then
	;

	: (interpret-token)
		2dup {: str len :}							( c-addr u -- c-addr u )
		find-name									( c-addr u -- 0 | nt )

		\ nt <> 0? (found)
		?dup if										( 0 | nt -- nt )
			\ compiling?
			state @ if
				name>compile						( nt -- xt action-xt )
			else name>interpret then				( nt -- xt )

			\ execute action
			execute									( xt -- )
		else str len (interpret-number) then		( -- )
	;

	: INTERPRET ( -- )
		begin
			parse-name dup		( -- c-addr u u )
		while					( c-addr u u -- c-addr u )
			(interpret-token)	( c-addr u -- )
		repeat

		2drop					( c- addr u -- )
	;
