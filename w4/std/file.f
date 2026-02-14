m4_require_w4(`std/constants.f')
m4_require_w4(`std/control.f')
m4_require_w4(`std/locals.f')
m4_require_w4(`std/parse-source.f')
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

	: OPEN-FILE ( c-addr u fam -- fileid ior )
		sp-2@ sp-2@ (new-file-src)	( c-addr u fam -- c-addr-u fam fid ) \ fid = here^
		{: path len rb fid :}		( c-addr u fam fid -- )

		\ dir fd (cwd = 3) & flags, path & len
		3 0 path len				( -- dir_fd dir_f c-addr u )

		\ of (no create/trunc), rights (base = fam, inherit = 0), file flags & fd
		0 rb 0 0					( dir_fd dir_f c-addr u -- dir_fd dir_f c-addr u of rb ri fd_f )
		fid (fid>fd^)				( dir_fd dir_f c-addr u of rb ri fd_f -- dir_fd dir_flags c-addr u of rb ri fd_f fd^ )

		\ call into host
		wasi::path_open				( dir_fd ... fd^ -- err )
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
	: (fid>idx++) ( fid -- ) dup (fid>in-pos@) 1+ swap (fid>in-pos!) ;

	: (read-char) ( buf fid -- no-eof no-err )
		true true \ only called by read-line, which already did eof check
		{: buf fid not-eof not-err :}

		fid (fid>in-pos@)			( -- pos )
		fid (fid>in-len@)			( pos -- pos len )

		\ (pos < len) == 0? (pos >= len?)
		u< 0= if
			fid (fid>in-ptr@)		( -- buf )
			(sizeof-fid-in)			( buf -- buf u )
			fid read-file			( buf u -- u ior )
			0= to not-err			( u ior -- u )	\ not-err = ior == 0

			\ not eof? (u <> 0)
			?dup if
				fid (fid>in-len!)	( u -- )
				0 fid (fid>in-pos!)
			else
				false to not-eof
				false fid (fid>is-eof!)
			then
		then

		\ not eof and not err?
		not-eof not-err and if
			\ populate buf with char
			fid (fid>in-ptr@)		( -- c-addr )
			fid (fid>in-pos@)		( c-addr -- c-addr u )
			+ c@ buf c!

			\ increment for next
			fid (fid>idx++)
		then

		not-eof not-err
	;

	: READ-LINE ( c-addr u fid -- u2 flag ior )
		dup (fid>is-eof@) 0= true true 0 				( c-addr u fid -- c-addr u fid not-eof not-eol not-err num )
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
				drop 						( no-eof -- )
				false to not-err
			then
		repeat

		num						( -- u2 )
		not-eof 0=				( u2 -- u2 eof? )
		num 0=					( u2 eof? -- u2 eof? n=0? )
		and	0=					( u2 eof? n=0? -- u2 flag ) \ f = eof & n=0
		not-err	0=				( u2 flag -- u2 flag ior )
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

\ https://forth-standard.org/standard/core/p
\
\ Parse ccc delimited by ) (right parenthesis). ( is an immediate word.
\
\ The number of characters in ccc may be zero to the number of characters in
\ the parse area.
\
\ NOTE: This is the later, multi-line version of our ( ... ) implementation

	\ (parse-multi) ( delim xt -- )
	\ Calls xt as ( c-addr u -- ) for each chunk.
	\ Stops when delim is found. If REFILL fails before delim, throws -14 (yours).
	: (parse-multi) ( ch xt -- )
		begin
			source nip >in @ - >r		( ch xt -- ch xt ) ( r: -- rem )
			sp-1@ parse					( ch xt -- ch xt c-addr u )
			dup r> < 0=	>r				( ch xt c-addr u -- ... ) ( r: rem -- more? ) \ more? = (u < rem) == 0
			sp-2@ execute				( ch xt c-addr u -- ch xt )
			r> 							( ch xt -- ch xt more? )
		while
			\ -14 interpreting a compile-only word
			refill 0= #-14 and throw
		repeat
		2drop							( ch xt -- )
	;

	: ( ')' ['] 2drop (parse-multi) ; immediate

(
	At this point in time we should have multi-line comments available
	to us. If things break at this point in the code, then... guess what,
	the above functions are not doing what they are supposed to do.
)
