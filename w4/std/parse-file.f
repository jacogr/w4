m4_require_w4(`std/control.f')
m4_require_w4(`std/file.f')
m4_require_w4(`std/interpret.f')
m4_require_w4(`std/parse.f')
m4_require_w4(`std/parse-source.f')
m4_require_w4(`std/stack-ptr.f')
m4_require_w4(`std/string.f')

m4_require_w4(`ext/hash.f')
m4_require_w4(`ext/list.f')

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

	: REFILL ( -- f )
		(source-current) dup				( -- fid )
		{: fid :}

		\ we need an fid
		if									( fid -- )
			\ non-zero flags? (file source)
			fid (fid>flags@) if
				fid (fid>ln-ptr@)			( -- c-addr )
				(sizeof-fid-ln)				( c-addr -- c-addr u )
				fid read-line				( c-addr u -- u2 ior )

				\ success = ior == 0
				0=							( u2 ior -- u2 f )

				\ success? zero pos & set len
				dup if						( u2 f -- u2 f )
					0 fid (fid>ln-pos!)
					swap fid (fid>ln-len!)	( u2 f -- f )
				else nip then				( u2 f -- f )
			else false then
		else false then
	;


\ https://forth-standard.org/standard/file/INCLUDE-FILE
\
\ Remove fileid from the stack. Save the current input source specification,
\ including the current value of SOURCE-ID. Store fileid in SOURCE-ID. Make
\ the file specified by fileid the input source. Store zero in BLK. Other
\ stack effects are due to the words included.
\
\ Repeat until end of file: read a line from the file, fill the input buffer
\ from the contents of that line, set >IN to zero, and interpret.
\
\ Text interpretation begins at the file position where the next file read
\ would occur.
\
\ When the end of the file is reached, close the file and restore the input
\ source specification to its saved value.
\
\ An ambiguous condition exists if fileid is invalid, if there is an I/O
\ exception reading fileid, or if an I/O exception occurs while closing fileid
\ When an ambiguous condition exists, the status (open or closed) of any
\ files that were being interpreted is implementation-defined.

	: -INCLUDE-FILE ( i * x fileid -- j * x )
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
			< if
				interpret
			else refill	to not-done	then
		repeat

		(source-set-prev)
	;

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

	: (if-not-included-add) ( c-addr u -- fid f )
		(included-wid) sp-2@ sp-2@		( c-addr u -- c-addr u wid c-addr u )
		2dup host::hash					( c-addr u wid c-addr u -- c-addr u wid c-addr u hash )
		(lookup-find)					( c-addr u wid c-addr u hash -- c-addr u nt )

		\ found?
		?dup if							( c-addr u nt -- c-addr u nt )
			2nip false					( c-addr u nt -- nt false )
		else							( c-addr u nt -- c-addr u )
			\ open file
			r/o open-file				( c-addr u -- fid ior )
			0<> #-38 and throw			( fid ior -- fid )

			\ append
			(included-wid)				( fid -- fid wid )
			swap (lookup-append)		( fid wid -- nt )
			true						( nt -- nt true )
		then

		\ extract fid from nt
		swap (nt>value@) swap			( nt f -- fid f )
	;

	: INCLUDED ( i * x c-addr u -- j * x )
		(if-not-included-add)			( c-addr u -- fid f )
		drop include-file				( fid f -- )
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
		(if-not-included-add)			( c-addr u -- fid f )
		if								( fid f -- fid )
			include-file				( fid -- )
		else drop then					( fid -- )
	;

\ https://forth-standard.org/standard/file/REQUIRE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of REQUIRED.

 	: REQUIRE ( i * x "name" -- j * x ) parse-name required ;
