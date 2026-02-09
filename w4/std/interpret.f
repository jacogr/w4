m4_require_w4(`std/compile.f')
m4_require_w4(`std/control.f')
m4_require_w4(`std/file.f')
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

	\ advance character
	: (interpret-skip-char) ( c-addr u -- c-addr' u' ) 1- swap 1+ swap ;

	\ handle prefixes and prostfixes
	: (interpret-number-prefix) ( c-addr u -- c-addr' u' isc? isd? mul nbase )
		false false 1 0								( c-addr u -- c-addr u isd? mul nbase )
		{: isc? isd? mul nbase :}					( c-addr u isc? isd? mul nbase -- c-addr u )

		\ test for char
		dup 3 = if
			over c@ ''' = if
				over 2 + c@ ''' = if
					true to isc?
				then
			then
		then

		isc? 0= if
			\ extract last char (double indicator)
			2dup 1- + c@							( c-addr u -- c-addr u char )

			\ char = '.'? (double value)
			'.' = if								( c-addr u char -- c-addr u )
				true to isd?
				1-									( c-addr u -- c-addr u' )
			then

			\ extract negative/base char
			over c@										( c-addr u -- c-addr u char )

			\ char == '-', negative
			dup '-' = if								( c-addr u char -- c-addr u char )
				drop									( c-addr u char -- c-addr u )
				(interpret-skip-char)
				-1 to mul
			else
				\ try to extract the base
				dup '$' <> if							( c-addr u char -- c-addr u char )
					dup '#' <> if						( c-addr u char -- c-addr u char )
						'%' = if $02 to nbase then
					else drop $0a to nbase then
				else drop $10 to nbase then

				\ have a base?
				nbase if
					(interpret-skip-char)
					over c@								( c-addr u -- c-addr u char )

					\ char == '-', negative
					'-' = if							( c-addr u char -- c-addr u )
						(interpret-skip-char)
						-1 to mul
					then
				then
			then
		then

		\ result
		isc? isd? mul nbase								( c-addr u -- c-addr' u' isc? isd? mul nbase )
	;

	\ try and convert the number
	: (interpret-number-conv) ( c-addr u -- n f )
		(interpret-number-prefix) base @ false			( c-addr u -- c-addr' u' isc? isd? mul nbase obase )
		{: str len isc? isd? mul nbase obase isc? :}	( c-addr u isd? mul nbase obase -- )

		isc? if
			str 1+ c@ 1									( -- ch 1 )
		else
			\ ensure valid length
			len 0> if
				\ set base, nbase <> 0 & nbase <> obase
				nbase 0<>
				nbase obase <>
				and if
					nbase base !
				else 0 to nbase then

				\ convert
				0 0 str len >number						( -- lo hi c-addr u )
				nip 									( lo hi c-addr u -- lo hi u )

				\ reset base
				nbase if obase base ! then

				0= if									( lo hi u -- lo hi )
					0= if								( lo hi -- lo )
						mul *							( lo -- n )
						isd? if -1 else 1 then 			( n -- n -1|1 )
					else drop 0 0 then					( lo -- 0 0 )
				else 2drop 0 0 then						( lo hi -- 0 0 )
			else 0 0 then								( -- 0 0 )
		then
	;

	: (interpret-number) ( c-addr u -- )
		(interpret-number-conv)						( c-addr u -- n f )

		\ f <> 0? (number converted)
		?dup if
			\ compiling?							( n f -- n f )
			state @ if
				(flg-xt-lit) swap					( n f -- n xtf f )

				-1 = if
					(flg-is-var) or					( n xtf -- n xtf' )
				then

				(new-xt) compile,					( n xtf -- )
			else
				-1 = if								( n xtf -- n )
					dup 0< if -1 else 0	then		( lo -- lo hi )
				then
			then
		else drop #-13 throw then					( n -- )
	;

	: (interpret-token)
		2dup {: str len :}							( c-addr u -- c-addr u )
		find-name									( c-addr u -- 0 | nt )

		\ nt <> 0? (found)
		?dup if										( 0 | nt -- nt )
			(nt>value@)								( nt -- xt )

			\ compiling?
			state @ if
				dup is-xt-immediate? if				( xt -- xt )
					execute							( xt -- )
				else compile, then					( xt -- )
			else execute then						( xt -- )
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

\ https://forth-standard.org/standard/core/REFILL
\ https://forth-standard.org/standard/file/REFILL
\
\ Attempt to fill the input buffer from the input source, returning a true
\ flag if successful.
\
\ When the input source is the user input device, attempt to receive input
\ into the terminal input buffer. If successful, make the result the input
\ buffer, set >IN to zero, and return true. Receipt of a line containing no
\ characters is considered successful. If there is no input available from
\ the current input source, return false.
\
\ When the input source is a string from EVALUATE, return false and perform
\ no other action.
\
\ When the input source is a text file, attempt to read the next line from
\ the text-input file. If successful, make the result the current input
\ buffer, set >IN to zero, and return true. Otherwise return false.

	: (refill-file) ( fid -- f )
		dup (fid>ln-ptr@)			( fid -- fid c-addr )
		(sizeof-fid-ln)				( fid c-addr -- fid c-addr u )
		sp-2@ read-line				( fid c-addr u -- fid u2 flag ior )

		\ success? zero pos & set len
		0= and if					( fid u2 flag ior -- fid u2 )
			0 sp-2@ (fid>ln-pos!)
			swap (fid>ln-len!)		( fid u2 -- )
			true
		else 2drop false then		( fid u2 -- f )
	;

	: REFILL ( -- f )
		(source-current)					( -- fid )

		\ we need an fid
		?dup if								( fid -- fid )
			\ non-zero flags? (file source)
			dup (fid>flags@) if				( fid -- fid )
				(refill-file)				( fid -- f )
			else drop false then			( fid -- f )
		else false then
	;

\ https://forth-standard.org/standard/core/EVALUATE
\
\ Save the current input source specification. Store minus-one (-1) in
\ SOURCE-ID if it is present. Make the string described by c-addr and u both
\ the input source and input buffer, set >IN to zero, and interpret. When the
\ parse area is empty, restore the prior input source specification. Other
\ stack effects are due to the words EVALUATEd.

	: (evaluate-source) ( fid -- )
		dup (source-set-next)		( fid -- fid )
		true						( fid -- fid not-done )
		{: fid not-done :}

		begin
			fid (fid>is-eof@) 0=
			not-done
			and
		while
			fid (fid>ln-pos@)		( -- pos )
			fid (fid>ln-len@)		( pos -- pos len )

			\ pos < len?
			u< if
				interpret
			else refill	to not-done	then
		repeat

		(source-set-prev)
	;

	: EVALUATE ( c-addr u -- ) (new-mem-src) (evaluate-source) ;
