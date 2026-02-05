m4_require_w4(`std/constants.f')
m4_require_w4(`std/control.f')
m4_require_w4(`std/locals.f')
m4_require_w4(`std/stack.f')
m4_require_w4(`std/string-search.f')
m4_require_w4(`std/value.f')

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

	\ aligned with wasm
	$100 constant (sizeof-fid-in)	\ 256
	$400 constant (sizeof-fid-ln)	\ 1024

	: (new-fileid) ( c-addr u -- fid )
		\ allocate, set path + hash
		align here (sizeof-fid) allot	( c-addr u -- c-addr u a-addr )
		-rot strdup						( c-addr u a-addr -- a-addr c-addr' u' )
		sp-2@ (xt>str+len+hash!)		( a-addr c-addr u -- a-addr )

		\ set line buffer
		here (sizeof-fid-ln) 1+ allot	( a-addr -- a-addr here )
		over (fid>ln-ptr!)				( a-addr here -- a-addr )

		\ set input buffer
		here (sizeof-fid-in) 1+ allot	( a-addr -- a-addr here )
		over (fid>in-ptr!)				( a-addr here -- a-addr )

		\ set flags
		(flg-is-vis)					( a-addr -- a-addr flags )	\ flags = visible
		over (fid>flags!)				( a-addr -- fid )
	;

	: OPEN-FILE ( c-addr u fam -- fileid ior )
		sp-2@ sp-2@ (new-fileid)	( c-addr u fam -- c-addr-u fam fid ) \ fid = here^
		{: path len rb fid :}		( c-addr u fam fid -- )

		\ currently we only open from cwd, preopened as dir_fd = 3
		3 0							( -- dir_fd dir_flags )

		\ path & len, output flags (no create/trunc)
		path len 0					( dir_fd dir_flags -- dir_fd dir_flags c-addr u of )

		\ rights (base = fam, inherit = 0), file flags & pointer
		rb 0						( dir_fd dir_flags c-addr u of -- dir_fd dir_flags c-addr u of rb ri )
		0 fid (fid>fd^)				( dir_fd dir_flags c-addr u of rb ri -- dir_fd dir_flags c-addr u of rb ri fd_flags fd )

		\ call into host
		wasi::path_open				( dir_fd ... fd -- err )
		dup 0= if fid else 0 then	( err -- err fileid )

		\ ior = 0 on success, -1 on failure
		swap 0<>					( err fileid -- fileid ior )
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

	: READ-FILE ( c-addr u fileid -- u2 ior )
		(fid>fd@) iov<fd?	( c-addr u fileid --  err nread )

		\ ior = 0 on success, -1 on failure
		swap 0<>			( err nread -- nread ior )
	;

\ https://forth-standard.org/standard/file/CLOSE-FILE
\
\ Close the file identified by fileid. ior is the implementation-defined
\ I/O result code.

	: CLOSE-FILE ( fileid -- ior ) (fid>fd@) wasi::fd_close 0<> ;

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

	: (fid>row++) ( fid -- ) dup (fid>row@) 1+ swap (fid>row!) ;

	: (read-char) ( buf fid -- no-eof no-err )
		true true
		{: buf fid not-eof not-err :}

		fid (fid>is-eof@) if
			false to not-eof
		else
			fid (fid>in-pos@)	( -- pos )
			1+ dup				( pos -- pos' pos' )

			\ pos < len?
			fid (fid>in-len@) < if
				fid (fid>in-pos!)
			else
				drop				( pos -- )
				fid (fid>in-ptr@)	( -- buf )
				(sizeof-fid-in)		( buf -- buf u )
				fid read-file		( buf u -- u ior )
				0= to not-err		( u ior -- u )	\ not-err = ior == 0

				\ not eof? (u <> 0)
				?dup if
					fid (fid>in-len!)
					0 fid (fid>in-pos!)
				else
					false to not-eof
					false fid (fid>is-eof!)
				then
			then
		then

		\ not eof and not err?
		not-eof not-err and if
			\ populate buf with char
			fid (fid>in-ptr@)
			fid (fid>in-pos@)
			+ c@ buf c!
		then

		not-eof not-err
	;

	: READ-LINE ( c-addr u fid -- u2 flag ior )
		true true true 0 								( c-addr u fid -- c-addr u fid not-eof not-eol not-err num )
		{: buf max fid not-eof not-eol not-err num :}	( c-addr u fid not-eof not-eol not-err num -- )

		begin
			num max <						( -- f1 )
			not-eof not-eol not-err			( f1 -- f1 not-eof not-eol not-err )
			and and and						( f1 not-eof not-eol not-err -- f )
		while								( f -- )
			buf fid (read-char)				( -- no-eof no-err )

			\ no err?
			if								( no-eof no-err -- no-eof )
				\ no eof?
				if							( no-eof -- )
					buf c@					( -- char )

					dup #10 = if			( char -- char )
						drop				( char -- )
						fid (fid>row++)
						false to not-eol
					else
						#13 <> if			( char -- )
							\ increment count & buf pos
							num 1+ to num
							buf 1+ to buf
						then
					then
				else
					false to not-eof		( -- )
				then
			else
				drop 						( no-err -- )
				false to not-err
			then
		repeat

		num						( -- u2 )
		not-eof 0=				( u2 -- u2 eof? )
		num 0=					( u2 eof? -- u2 eof? n=0? )
		and						( u2 eof? n=0? -- u2 flag ) \ f = eof & n=0
		not-err	0=				( u2 flag -- u2 flag ior )
	;
