m4_require_w4(`std/constants.f')
m4_require_w4(`std/control.f')
m4_require_w4(`std/string-utils.f')

m4_require_w4(`ext/hash.f')
m4_require_w4(`ext/list.f')
m4_require_w4(`ext/is.f')

\ Helpers first encoutered here... move these elsewhere
\ (NOTE: host::hash dependency)

	: (xt>str+len+hash!) ( c-addr len xt -- )
		3dup (xt>str+len!)				( c-addr len xt -- c-addr len xt )
		-rot host::hash swap			( c-addr len xt -- hash xt )
		(xt>hash!)						( hash xt -- )
	;

	: (new-xt-full) ( c-addr u val flags -- xt )
		(new-xt) -rot					( c-addr u val flags -- xt c-addr u )
		strdup							( xt c-addr u -- xt c-addr' u )
		sp-2@ (xt>str+len+hash!)		( xt c-addr u -- xt )
	;

\ https://forth-standard.org/standard/string/REPLACES
\
\ Set the string c-addr1 u1 as the text to substitute for the substitution
\ named by c-addr2 u2. If the substitution does not exist it is created.
\ The program may then reuse the buffer c-addr1 u1 without affecting the
\ definition of the substitution.

	(new-lookup-small) constant (subst-wid)

	2variable (subst-dst+len)
	variable (subst-dlen)
	variable (subst-err)

	: (lookup-string-append) ( c-addr len wid -- a-addr )
		\ create xt
		-rot							( c-addr len wid -- wid c-addr len )
		$0 (flg-is-vis) (new-xt-full)	( wid c-addr len -- xt )

		\ allocate string buffer at here
		here swap						( wid xt -- wid here^ xt )
		string-max 1+ allot				( wid here^ xt -- wid here^ xt )

		\ store buffer as xt>value
		2dup (xt>value!)				( wid here^ xt -- wid here^ xt )

		\ add to wordlist
		rot swap						( wid here^ xt -- here^ wid xt )
		(lookup-append)					( here^ wid xt -- here^ nt )
		drop							( here^ nt -- here^ )
	;

	: (make-subst)	( c-addr u -- c-addr ) (subst-wid) (lookup-string-append) ;
	: (find-subst) ( c-addr u -- c-addr | 0 ) (subst-wid) (lookup-search-xt) (xt>value@) ;

	: REPLACES ( text tlen name nlen -- )
		\ found?
		2dup (find-subst) ?dup if
			2nip
		else (make-subst) then

		\ place with len != 0
		over 0<> if
			place
		else 3drop then
	;

\ https://forth-standard.org/standard/string/SUBSTITUTE
\
\ Perform substitution on the string c-addr1 u1 placing the result at
\ string c-addr2 u3, where u3 is the length of the resulting string. An
\ error occurs if the resulting string will not fit into c-addr2 u2 or
\ if c-addr2 is the same as c-addr1. The return value n is positive or
\ 0 on success and indicates the number of substitutions made. A negative
\ value for n indicates that an error occurred, leaving c-addr2 u3 undefined

	: (add-subst-dst) ( char -- )
		\ not at end?
		(subst-dst+len) @ (subst-dlen) @ < if
			\ xero error?
			(subst-err) @ 0= if
				\ add character, increment offset
				(subst-dst+len) 2@ + c!
				$1 (subst-dst+len) +!
			else drop then
		else drop -1 (subst-err) ! then
	;

	: (form-subst-name) ( c-addr u -- c-addr1 u1 c-addr2 u2 )
		1 /string				( c-addr u -- c-addr' u' )

		2dup '%' scan			( c-addr u -- c-addr u c-addr' u' )
		dup if					( c-addr u c-addr' u' u' -- c-addr u c-addr' u' )
			swap drop			( c-addr u c-addr' u' -- c-addr u u' )
			sp-2@ sp-2@			( c-addr u u' -- c-addr u u' c-addr u )
			rot					( c-addr u u' -- c-addr u c-addr u u' )
			- 2>r r@			( c-addr u c-addr u u' -- c-addr u u2 ) ( r: -- c-addr2 u2 )
			1+ /string			( c-addr u u' -- c-addr1 u1 )
			2r>					( c-addr1 u1 -- c-addr1 u1 c-addr2 u2 )
		then
	;

	: (to-subst-dst) ( c-addr u -- ) bounds ?do i c@ (add-subst-dst) $1 +loop ;

	: (layout-subst-name) ( -- )
		2dup (find-subst) ?dup if
			2nip
			count (to-subst-dst)
			true
		else
			'%' (add-subst-dst)
			(to-subst-dst)
			'%' (add-subst-dst)
			false
		then
	;

	: SUBSTITUTE ( src slen dst dlen -- dst len' n )
		\ as per spec, overlap error
		2over 2over							( src slen dst dlen --  src slen dst dlen src slen dst dlen )
		is-overlapped? if					( src slen dst dlen src slen dst dlen -- src slen dst dlen )
			drop 2nip						( src slen dst dlen -- dst )
			0 -1							( dst -- dst 0 -1 )
			exit
		then

		\ setup buffers
		(subst-dlen) !						( src slen dst dlen -- src slen dst )
		0 (subst-dst+len) 2!				( src slen dst -- src slen )
		0 (subst-err) !

		\ add initial n = 0
		0 -rot								( src slen -- n src slen )

		begin
			dup 0>
		while
			\ not %?
			over c@ '%' <> if
				over c@ (add-subst-dst)
				$1 /string
			else
				\ %%?
				over 1+ c@ '%' = if
					'%' (add-subst-dst)
					$2 /string
				else
					\ start & end %?
					(form-subst-name) dup if
						(layout-subst-name)
						if rot 1+ -rot then	( n src slen n -- n' src slen )
					else
						2drop
						'%' (add-subst-dst)
					then
				then
			then
		repeat

		2drop (subst-dst+len) 2@			( n src slen -- n dst dlen )
		rot									( n dst dlen -- dst dlen n )

		\ error?
		(subst-err) @ if
			drop
			(subst-err) @ 	\ negative n for error
		then
	;
