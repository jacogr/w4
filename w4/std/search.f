require constants.f
require list.f
require loops.f
require stack.f
require ../ext/hash.f

\ https://forth-standard.org/standard/search/WORDLIST
\
\ Create a new empty word list, returning its word list identifier wid.
\ The new word list may be returned from a pool of preallocated word lists
\ or may be dynamically allocated in data space. A system shall allow the
\ creation of at least 8 new word lists in addition to any provided as part
\ of the system.

	: wordlist ( -- wid ) (new-lookup-small) ;

\ https://forth-standard.org/standard/search/GET-CURRENT
\
\ Return wid, the identifier of the compilation word list.

	variable (wordlist-current) (dict^) (wordlist-current) !

	: get-current ( -- wid ) (wordlist-current) @ ;

\ https://forth-standard.org/standard/search/SET-CURRENT
\
\ Set the compilation word list to the word list identified by wid.

	: set-current ( wid -- ) (wordlist-current) @ ! ;

\ https://forth-standard.org/standard/search/SEARCH-WORDLIST
\
\ Find the definition identified by the string c-addr u in the word list
\ identified by wid. If the definition is not found, return zero. If the
\ definition is found, return its execution token xt and one (1) if the
\ definition is immediate, minus-one (-1) otherwise.

	: >lower-ascii ( c -- c' ) dup 'A' 'Z' 1+ within if $20 or then ;

	: strdup-n-lower ( c-addr u -- c-addr2 u )
		swap over				( c-addr u -- len src u )
		here swap				( len src u -- len src dst u )
		allot					( len src dst u -- len src dst )
		sp-2@					( len src dst u -- len src dst u )

		begin
			dup 0<>				( len src dst u -- len src dst u f )
		while					( len src dst u f -- len src dst u )
			1- 2dup				( len src dst u -- len src dst u' u' u' )
			sp-4@ + c@			( len src dst u u u -- len src dst u u c )
			>lower-ascii		( len src dst u u c -- len src dst u u c' )
			swap sp-3@ + c!		( len src dst u u c -- len src dst u )
		repeat

		drop nip				( len src dst u -- len dst )
		swap					( len dst -- dst len )
	;

	: search-wordlist ( c-addr u wid -- 0 | xt 1 | xt -1 )
		-rot strdup-n-lower			( c-addr u wid -- wid c-addr' u' )
		2dup host::hash				( wid c-addr u -- wid c-addr u hash )
		(lookup-find)				( wid c-addr u hash -- nt|0 )

		\ found the nt?
		?dup if
			(name>value@) dup		( nt -- xt xt )
			(xt>flags@)				( xt xt -- xt flags )

			\ immediate?
			(flg-set-imm) and if
				1					( xt -- xt 1 )
			else
				-1					( xt -- xt -1 )
			then
		then
	;
