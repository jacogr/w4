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

	$00000000 constant W/O

\ https://forth-standard.org/standard/file/RDivW
\
\ fam is the implementation-defined value for selecting the "read/write"
\ file access method.

	$00000000 constant R/W

\ https://forth-standard.org/standard/file/CLOSE-FILE
\
\ Close the file identified by fileid. ior is the implementation-defined
\ I/O result code.

	: CLOSE-FILE ( fd -- ior ) wasi::fd_close ;

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
		wasi::path_open		( dir_fd ... fd -- errno )
		dup 0= if
			(opened-fd) @	( ior -- ior fileid )
		else 0 then			( ior -- ior fileid )

		swap				( ior fileid -- fileid ior )
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
		iov<fd?		( c-addr u fd -- errno nread )
		swap		( errno nread -- nread errno )
	;
