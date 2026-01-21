require constants.f
require list.f
require loops.f
require stack.f

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

	: search-wordlist ( c-addr u wid -- 0 | xt 1 | xt -1 )
		-rot (lookup-search)		( c-addr u wid -- nt|0 )

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
