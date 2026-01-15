require stack.f

\ Helper to wrap the wasi:fd_write for use in type & emit

	create (iov-tmp-nwrite) $1 cells allot

	: iov>fd ( c-addr-u u 1|2 -- ) \ 1=stdout, 2=stderr
		#2 (sp@-) 			( c-addr u 1|2 -- c-addr u 1|2 a-iov )
		1 					\ write a single iov
		(iov-tmp-nwrite)	( c-addr u 1|2 a-iov 1 -- c-addr u 1|2 a-iov 1 a-tmp )
		wasi::fd_write		( c-addr u 1|2 a-iov 1 a-tmp -- c-addr u err )
		0<> #-37 and throw	( c-addr u err -- c-addr u )
		2drop				( c-addr u -- )
	;

\ Helper to wrap the wasi:fd_read interface for the keyboard

	create (iov-tmp-in)     $2 cells allot   \ wasi iovec: buf_ptr, buf_len
	create (iov-tmp-nread)  $1 cells allot   \ size_t
	create (key-buf)        $1 allot

	: iov! ( c-addr u a-iov -- )
		>r 				( c-addr u a-iov -- c-addr u ) ( r: -- a-iov )
		r@ 1 cells + !	( c-addr u -- c-addr ) ( r: a-iov ) \ store u at [a-iov + 1 cell]
		r> ! 			( c-addr -- )                       \ store c-addr at [a-iov + 0]
	;

	: iov<fd? ( c-addr u fd -- errno nread )
		>r 					( c-addr u fd -- c-addr u ) ( r: -- fd )
		(iov-tmp-in) iov! 	( c-addr u -- ) ( r: fd )
		r> 					( -- fd )                             \ restore fd
		(iov-tmp-in) 		( fd -- fd iovs_ptr )                 \ iovs_ptr
		1 					( ... -- fd iovs_ptr iovs_len )       \ iovs_len = 1
		(iov-tmp-nread) 	( ... -- fd iovs_ptr iovs_len nread_ptr )
		wasi::fd_read 		( ... -- errno )                      \ call wrapper → errno
		(iov-tmp-nread) @	( errno -- errno nread )              \ fetch nread
	;

	: iov<fd ( c-addr u fd -- nread )
		iov<fd?					( errno nread )
		swap 0<> #-37 and throw	( nread )
	;



