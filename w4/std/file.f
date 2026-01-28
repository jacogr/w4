m4_require_w4(`std/constants.f')

m4_require_w4(`ext/wasi.f')

\ https://forth-standard.org/standard/file/RDivO
\
\ fam is the implementation-defined value for selecting the "read only"
\ file access method.

	\ 1<<1  FD_READ         = $00000002
	\ 1<<21 FD_FILESTAT_GET = $00200000
	$00200002 constant R/O

\ https://forth-standard.org/standard/file/WDivO
\
\ fam is the implementation-defined value for selecting the "write only"
\ file access method.
\
\ TODO Only file reads available at this point
\
\	$00000000 constant W/O

\ https://forth-standard.org/standard/file/RDivW
\
\ fam is the implementation-defined value for selecting the "read/write"
\ file access method.
\
\ TODO Only file reads available at this point
\
\	$00000000 constant R/W

\ https://forth-standard.org/standard/file/CLOSE-FILE
\
\ Close the file identified by fileid. ior is the implementation-defined
\ I/O result code.

	: CLOSE-FILE ( fd -- ior ) wasi::fd_close 0<> ;

\ https://forth-standard.org/standard/file/OPEN-FILE
\
\ Open the file named in the character string specified by c-addr u, with
\ file access method indicated by fam. The meaning of values of fam is
\ implementation defined.
\
\ If the file is successfully opened, ior is zero, fileid is its identifier
\ and the file has been positioned to the start of the file.
\
\ Otherwise, ior is the implementation-defined I/O result code and fileid
\ is undefined.

	$1 cells buffer: (opened-fd)

	: OPEN-FILE ( c-addr u fam -- fileid ior )
		\ store fam, used as rights_base
		>r					( c-addr u fam -- c-addr u ) ( r: -- fam )

		\ currently we only open from cwd, preopened as dir_fd = 3
		3 -rot				( c-addr u -- dir_fd c-addr u )
		0 -rot				( dir_fd c-addr u -- dir_fd dir_flags c-addr u )

		\ output flags (no create/trunc)
		0					( dir_fd dir_flags c-addr u -- dir_fd dir_flags c-addr u of )

		\ rights (base = fam, inherit = 0), file flags & pointer
		r> 0				( dir_fd dir_flags c-addr u of -- dir_fd dir_flags c-addr u of rb ri ) ( r: fam -- )
		0 (opened-fd)		( dir_fd dir_flags c-addr u of rb ri -- dir_fd dir_flags c-addr u of rb ri fd_flags fd )

		\ call into host
		wasi::path_open		( dir_fd ... fd -- err )
		dup 0= if
			(opened-fd) @	( err -- err fileid )
		else 0 then			( err -- err fileid )

		\ ior = 0 on success, -1 on failure
		swap 0<>			( err fileid -- fileid ior )
	;

\ https://forth-standard.org/standard/file/READ-FILE
\
\ Read u1 consecutive characters to c-addr from the current position of the
\ file identified by fileid.
\
\ If u1 characters are read without an exception, ior is zero and u2 is equal
\ to u1.
\
\ If the end of the file is reached before u1 characters are read, ior is zero
\ and u2 is the number of characters actually read.
\
\ If the operation is initiated when the value returned by FILE-POSITION is
\ equal to the value returned by FILE-SIZE for the file identified by fileid,
\ ior is zero and u2 is zero.
\
\ If an exception occurs, ior is the implementation-defined I/O result code,
\ and u2 is the number of characters transferred to c-addr without an
\ exception.
\
\ An ambiguous condition exists if the operation is initiated when the value
\ returned by FILE-POSITION is greater than the value returned by FILE-SIZE
\ for the file identified by fileid, or if the requested operation attempts
\ to read portions of the file not written.
\
\ At the conclusion of the operation, FILE-POSITION returns the next file
\ position after the last character read.

	: READ-FILE ( c-addr u fd -- u2 ior )
		iov<fd?		( c-addr u fd -- err nread )

		\ ior = 0 on success, -1 on failure
		swap 0<>	( err nread -- nread ior )
	;

\ https://forth-standard.org/standard/file/READ-LINE
\
\ Read the next line from the file specified by fileid into memory at the
\ address c-addr. At most u1 characters are read. Up to two implementation-
\ defined line-terminating characters may be read into memory at the end of
\ the line, but are not included in the num u2. The line buffer provided
\ by c-addr should be at least u1+2 characters long.
\
\ If the operation succeeded, flag is true and ior is zero. If a line
\ terminator was received before u1 characters were read, then u2 is the
\ number of characters, not including the line terminator, actually read
\ (0 <= u2 <= u1). When u1 = u2 the line terminator has yet to be reached.
\
\ If the operation is initiated when the value returned by FILE-POSITION is
\ equal to the value returned by FILE-SIZE for the file identified by fileid,
\ flag is false, ior is zero, and u2 is zero. If ior is non-zero, an exception
\ occurred during the operation and ior is the implementation-defined I/O
\ result code.
\
\ An ambiguous condition exists if the operation is initiated when the value
\ returned by FILE-POSITION is greater than the value returned by FILE-SIZE
\ for the file identified by fileid, or if the requested operation attempts to
\ read portions of the file not written.
\
\ At the conclusion of the operation, FILE-POSITION returns the next file
\ position after the last character read.

	$1 cells buffer: (file-line-buf)

	: READ-LINE ( c-addr u fd -- u2 flag ior )
		0 true 2>r 0 >r						( r: -- ior ok? num )
		true								( c-addr u fd -- c-addr u fd f )

		begin
			r-0@ sp-2@ <					( c-addr u fd f -- c-addr u fd f f1 )	\ f1 = num < u?
			and								( c-addr u fd f f1 -- c-addr u fd f' )	\ f' = f & f1
			r-1@ and						( c-addr u fd f -- c-addr u fd f' )		\ f' = f & ok?
			dup 							( c-addr u fd f -- c-addr u fd f f )
		while								( c-addr u fd f f -- c-addr u fd f )
			\ setup and read a single character
			(file-line-buf) 1 sp-3@			( c-addr u fd f -- c-addr u fd f buf 1 fd )
			read-file						( c-addr u fd f buf 1 fd -- c-addr u fd f u2 err )

			\ store errorno as ior
			0<> dup r-2!					( c-addr u fd f u2 err -- c-addr u fd f u2 ior' ) ( r: ior ok? num -- ior' ok? num )

			\ ior <> 0?
			0<> if							( c-addr u fd f u2 ior -- c-addr u fd f u2 )
				drop						( c-addr u fd f u2 -- c-addr u fd f )
				false r-1!					( r: ok? num -- false num )
			else
				\ u2 == 0? (eof)
				0= if
					false r-1!				( r: ior ok? num -- ior false num )
				else
					\ retrieve first char
					(file-line-buf) c@		( c-addr u fd f u2 -- c-addr u fd f u2 char )

					\ char == 10? (lf)
					dup 10 = if				( c-addr u fd f u2 char -- c-addr u fd f u2 char )
						3drop false 		( c-addr u fd f u2 char -- c-addr u fd false )
					else
						\ char <> 13? (cr)
						dup 13 <> if		( c-addr u fd f u2 char -- c-addr u fd f u2 char )
							sp-5@ r@ + c!	( c-addr u fd f u2 char -- c-addr u fd f u2 )
							r> + >r			( c-addr u fd f u2 -- c-addr u fd f ) ( r: ior ok? num -- ior ok? num' ) \ num' = num + u2
						then
					then
				then
			then
		repeat

		4drop		( c-addr u fd f -- )
		r> 2r>		( -- num ior ok? ) ( r: ior ok? num -- )
		0<>	swap	( num ior ok? -- num f ior )
	;
