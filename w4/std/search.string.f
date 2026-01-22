include constants.f
include loops.f
include search.f
include string.utils.f

\ Helpers first encoutered here... move these elsewhere
\ (NOTE: host::hash dependency)

	: (xt>str+len+hash!) ( c-addr len xt -- )
		3dup (xt>str+len!)				( c-addr len xt -- c-addr len xt )
		-rot host::hash swap			( c-addr len xt -- hash xt )
		(xt>hash!)						( hash xt -- )
	;

\ https://forth-standard.org/standard/string/REPLACES
\
\ Set the string c-addr1 u1 as the text to substitute for the substitution
\ named by c-addr2 u2. If the substitution does not exist it is created.
\ The program may then reuse the buffer c-addr1 u1 without affecting the
\ definition of the substitution.

	(new-lookup-small) constant (widSubst)

	: (makeSubst)	( c-addr len -- c-addr )
		strdup-n-lower					( c-addr len -- c-addr' len' )
		0 (flg-set-vis) (new-xt)		( c-addr len -- c-addr len xt )
		-rot							( c-addr len xt -- xt c-addr len )
		sp-2@ (xt>str+len+hash!)		( xt c-addr len -- xt )
		here swap						( xt -- here^ xt )
		string-max 1+ allot				\ allocate string buffer at here
		2dup (xt>value!)				( here^ xt -- here^ xt )
		(widSubst) swap					( here^ xt -- here^ wid xt )
		(lookup-append)					( here^ wid xt -- here^ nt )
    	drop							( here^ nt -- here^ )
   ;

	: (findSubst) ( c-addr len -- a-addr|0 )
   		(widSubst) (lookup-search-xt)	( c-addr len -- xt|0 )
		(xt>value@)						( xt|0 -- a-addr|0 )
	;

	: replaces ( text tlen name nlen -- )
		2dup (findSubst)				( text tlen name nlen -- text tlen name nlen dst )
		?dup if
			2nip 						( text tlen name nlen dst -- text tlen dst )
		else
			(makeSubst)					( text tlen name nlen -- text tlen dst )
		then
		place							( text tlen dst -- )
	;

\ https://forth-standard.org/standard/string/SUBSTITUTE
\
\ Perform substitution on the string c-addr1 u1 placing the result at
\ string c-addr2 u3, where u3 is the length of the resulting string. An
\ error occurs if the resulting string will not fit into c-addr2 u2 or
\ if c-addr2 is the same as c-addr1. The return value n is positive or
\ 0 on success and indicates the number of substitutions made. A negative
\ value for n indicates that an error occurred, leaving c-addr2 u3 undefined

	string-max 1+ buffer: (substName)	\ Holds substitution name as a counted string.

	variable (substDestLen)			\ Maximum length of the destination buffer.
	variable (substDestAddr)   		\ destination base address
	variable (substDestCur)    		\ current length
	variable (substErr)				\ Holds zero or an error code.

	: (addDestSubst) ( char -- )
		(substDestCur) @ (substDestLen) @ < if
			(substDestAddr) @
			(substDestCur) @ + c!          \ store char
			1 (substDestCur) +!            \ advance length
		else
			drop -1 (substErr) !
		then
	;

	: (formNameSubst) ( c-addr len -- c-addr' len' )
		1 /string 2dup '%' scan >r drop			\ find length of residue
		2dup r> - dup >r (substName) place 		\ save name in buffer
		r> 1 chars + /string 					\ step over name and trailing %
	;

	: >dest ( c-addr len -- )
		bounds ?do
			i c@ (addDestSubst)
		1 chars +loop
	;

	: (processNameSubst) ( -- flag )
		(substName) count
		(findSubst)          \ xt|0
		?dup if
			\ found
			count >dest
			true
		else
			\ not found
			'%' (addDestSubst)
			(substName) count >dest
			'%' (addDestSubst)
			false
		then
	;

	: substitute ( src slen dest dlen -- dest dlen' n )
		(substDestLen) !
		(substDestAddr) !
		0 (substDestCur) !
		0 (substErr) !

		\ error if src == dest
		2over drop 2over drop = if
			2drop 2drop 0 0 -1 exit
		then

		0 -rot							( src slen dest dlen -- n src u )

		begin
			dup 0 >
		while
			over c@ '%' <> if
				\ normal character
				over c@ (addDestSubst)
				1 /string
			else
				\ saw '%'
				dup 1 > if
					\ safe to look at next char
					over 1 chars + c@ '%' = if
						\ %% -> literal %
						'%' (addDestSubst)
						2 /string
					else
						\ %name% (or %name with no closing %, handled by formNameSubst)
						(formNameSubst)				\ ( n src u -- n src' u' )
						(processNameSubst) if		\ increments only if found
							rot 1+ -rot
						then
					then
				else
					\ single trailing '%'
					'%' (addDestSubst)
					1 /string
				then
			then
		repeat

		2drop
		(substDestAddr) @
		(substDestCur) @
		rot

		(substErr) @ if
			drop (substErr) @
		then
	;
