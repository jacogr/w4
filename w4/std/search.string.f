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
		(new-xt) -rot					( c-addr len -- xt c-addr len )
		sp-2@ (xt>str+len+hash!)		( xt c-addr len -- xt )
		here swap						( xt -- here^ xt )
		2dup (xt>value!)				( here^ xt -- here^ xt )
		(widSubst) swap					( here^ xt -- here^ wid xt )
		(lookup-append)					( here^ wid xt -- here^ nt )
    	drop							( here^ nt -- here^ )
   ;

	: (findSubst) ( c-addr len -- xt|0 )
   		(widSubst) (lookup-search)		( c-addr len -- nt|0 )
		(name>value@) (xt>value@)		( nt|0 -- xt|0 )
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

	string-max buffer: (substName)	\ Holds substitution name as a counted string.

	variable (substDestLen)			\ Maximum length of the destination buffer.
	2variable (substDest)			\ Holds destination string current length and address.
	variable (substErr)				\ Holds zero or an error code.

	: (addDestSubst) ( char -- )
		(substDest) @ (substDestLen) @ < if
			(substDest) 2@ + C! 1 chars (substDest) +!
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
		(substName) count (findSubst)

		dup >r if
			EXECUTE count >dest
		else
			'%' (addDestSubst)
			(substName) count >dest
			'%' (addDestSubst)
		then

		r>
	;

	: substitute ( src slen dest dlen -- dest dlen' n )
		(substDestLen) ! 0 (substDest) 2! 0 -rot \ -- 0 src slen
		0 (substErr) !

		begin
			dup 0 >
		while
			over c@ '%' <> if 				\ character not %
				over c@ (addDestSubst) 1 /string
			else
				over 1 chars + c@ '%' = if	\ %% for one output %
					'%' (addDestSubst)
					2 /string 				\ add one % to output
				else
					(formNameSubst) (processNameSubst) if
					rot 1+ -rot 			\ count substitutions
					then
				then
			then
		repeat

		2drop (substDest) 2@ rot (substErr) @ if
			drop (substErr) @
		then
	;
