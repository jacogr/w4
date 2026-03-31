m4_require(<!std/control.f!>)
m4_require(<!std/file.f!>)
m4_require(<!std/interpret.f!>)
m4_require(<!std/parse.f!>)
m4_require(<!std/parse-source.f!>)
m4_require(<!std/stack-ptr.f!>)
m4_require(<!std/string.f!>)

m4_require(<!ext/hash.f!>)
m4_require(<!ext/list.f!>)

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

	: INCLUDE-FILE ( i * x fileid -- j * x ) (evaluate-source) ;

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
	$400 buffer: (included-rel-buf)

	: (last-slash-idx) ( c-addr u -- n|-1 )
		{: ptr len | idx at :}

		-1 to at

		len 0<> if
			len 1- to idx

			begin
				idx 0< 0=
				at -1 =
				and
			while
				ptr idx + c@ #47 = if
					idx to at
				else
					idx 1- to idx
				then
			repeat
		then

		at
	;

	: (open-file-maybe-rel) ( c-addr u -- fid ior )
		{: req req-len | fid ior cur src src-len dir-len :}

		\ direct open first
		req req-len r/o open-file
		to ior
		to fid

		\ try include-relative fallback on failure
		ior if
			\ absolute paths are not resolved relative to current source
			req c@ #47 <> if
				(source-current) to cur
				cur if
					cur (fid>flags@) if
						cur (fid>path+len@)
						to src-len
						to src

						src src-len (last-slash-idx)
						dup 0< 0= if
							1+ to dir-len

							\ room in local scratch?
							dir-len req-len + dup $400 u< if
								drop
								src (included-rel-buf) dir-len move
								req (included-rel-buf) dir-len + req-len move

								(included-rel-buf) dir-len req-len + r/o open-file
								to ior
								to fid
							else
								drop
							then
						else
							drop
						then
					then
				then
			then
		then

		fid ior
	;

	: (fid-path-set-dup) ( c-addr u fid -- )
		>r
		strdup
		2dup r@ (fid>path+len!)
		host::hash r> (fid>hash!)
	;

	: (fid-rewind) ( fid -- fid )
		dup >r

		\ reset host file position
		$0 $0 r@ reposition-file drop

		\ reset read/line state for subsequent include-file
		$0 r@ (fid>is-eof!)
		$0 r@ (fid>in-len!)
		$0 r@ (fid>in-pos!)
		$0 r@ (fid>ln-len!)
		$0 r@ (fid>ln-pos!)

		drop r>
	;

	: (if-not-included-add) ( c-addr u -- fid f )
		(included-wid) sp-2@ sp-2@		( c-addr u -- c-addr u wid c-addr u )
		2dup host::hash					( c-addr u wid c-addr u -- c-addr u wid c-addr u hash )
		(lookup-find)					( c-addr u wid c-addr u hash -- c-addr u nt )

		\ found?
		?dup if							( c-addr u nt -- c-addr u nt )
			2nip false					( c-addr u nt -- nt false )
		else							( c-addr u nt -- c-addr u )
			\ open file
			2dup (open-file-maybe-rel)	( c-addr u -- c-addr u fid ior )
			0<> #-38 and throw			( fid ior -- fid )
			dup >r						( c-addr u fid -- c-addr u fid ) ( r: -- fid )
			(fid-path-set-dup)			( c-addr u fid -- )
			r>							( -- fid )

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
		drop (fid-rewind) include-file	( fid f -- )
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
