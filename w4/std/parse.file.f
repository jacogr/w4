m4_require_w4(`std/file.f')
m4_require_w4(`std/loops.f')
m4_require_w4(`std/stack.f')
m4_require_w4(`std/string.f')

m4_require_w4(`ext/hash.f')
m4_require_w4(`ext/list.f')

\ https://forth-standard.org/standard/file/INCLUDED
\
\ Remove c-addr u from the stack. Save the current input source specification,
\ including the current value of SOURCE-ID. Open the file specified by c-addr u,
\ store the resulting fileid in SOURCE-ID, and make it the input source. Store
\ zero in BLK. Other stack effects are due to the words included.
\
\ Repeat until end of file: read a line from the file, fill the input buffer
\ from the contents of that line, set >IN to zero, and interpret.
\
\ Text interpretation begins at the start of the file.
\
\ When the end of the file is reached, close the file and restore the input source
\ specification to its saved value.
\
\ An ambiguous condition exists if the named file can not be opened, if an I/O
\ exception occurs reading the file, or if an I/O exception occurs while closing
\ the file. When an ambiguous condition exists, the status (open or closed) of any
\ files that were being interpreted is implementation-defined.
\
\ INCLUDED may allocate memory in data space before it starts interpreting the file.

	(new-lookup-small) constant (included-wid)

	: (if-not-included-add) ( c-addr u -- c-addr u f )
		(included-wid) sp-2@ sp-2@		( c-addr u -- c-addr u wid c-addr u )
		2dup host::hash					( c-addr u wid c-addr u -- c-addr u wid c-addr u hash )
		(lookup-find)					( c-addr u wid c-addr u hash -- c-addr u a-addr )

		\ append if not found
		0= if
			(included-wid)				( c-addr u -- c-addr u wid )
			(lookup-string-append)		( c-addr u wid -- a-addr )
			drop true					( a-addr -- c-addr u f )
		else 2drop false then			( c-addr u -- f )
	;

	: INCLUDED ( i * x c-addr u -- j * x )
		2dup (if-not-included-add)		( c-addr u -- c-addr u f )
		drop included					( c-addr u f -- )
	;

\ https://forth-standard.org/standard/file/INCLUDE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of INCLUDED.

	: INCLUDE ( i * x "name" -- j * x ) parse-name included	;

\ https://forth-standard.org/standard/file/REQUIRED
\
\ If the file specified by c-addr u has been INCLUDED or REQUIRED already,
\ but not between the definition and execution of a marker (or equivalent
\ usage of FORGET), discard c-addr u; otherwise, perform the function of
\ INCLUDED.
\
\ An ambiguous condition exists if a file is REQUIRED while it is being
\ REQUIRED or INCLUDED.
\
\ An ambiguous condition exists, if a marker is defined outside and executed
\ inside a file or vice versa, and the file is REQUIRED again.
\
\ An ambiguous condition exists if the same file is REQUIRED twice using different
\ names (e.g., through symbolic links), or different files with the same name are
\ REQUIRED (by doing some renaming between the invocations of REQUIRED).
\
\ An ambiguous condition exists if the stack effect of including the file is not
\ ( i * x -- i * x ).

	: REQUIRED ( i * x c-addr u -- i * x )
		2dup (if-not-included-add) if	( c-addr u -- c-addr u )
			included					( c-addr u -- )
		else 2drop then					( c-addr u -- )
	;

\ https://forth-standard.org/standard/file/REQUIRE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of REQUIRED.

 	: REQUIRE ( i * x "name" -- j * x ) parse-name required ;
