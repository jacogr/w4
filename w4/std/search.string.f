include constants.f
include loops.f
include search.f
include string.c.f

\ https://forth-standard.org/standard/string/REPLACES
\
\ Set the string c-addr1 u1 as the text to substitute for the substitution
\ named by c-addr2 u2. If the substitution does not exist it is created.
\ The program may then reuse the buffer c-addr1 u1 without affecting the
\ definition of the substitution.

	(new-lookup-tiny) constant (widSubst)

	: (xt>string!) ( c-addr len xt -- )
		swap over		( c-addr len xt -- c-addr xt len xt )
		sp-3@ sp-2@		( c-addr xt len xt -- c-addr xt len xt c-addr len )
		host::hash over	( c-addr xt len xt c-addr len -- c-addr x len xt hash xt )
		(xt>hash!)		( c-addr x len xt hash xt -- c-addr x len xt )
		(xt>len!)		( c-addr xt len xt -- c-addr xt )
		(xt>str!)		( c-addr xt -- )
	;

	: (makeSubst)	( c-addr len -- c-addr )
		strdup-n-lower					( c-addr len -- c-addr' len' )
		(new-xt) -rot					( c-addr len -- xt c-addr len )
		sp-2@ (xt>string!)				( xt c-addr len -- xt )
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
