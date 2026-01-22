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

\ https://forth-standard.org/standard/search/GET-ORDER
\
\ Returns the number of word lists n in the search order and the word list
\ identifiers widn ... wid1 identifying these word lists. wid1 identifies
\ the word list that is searched first, and widn the word list that is
\ searched last. The search order is unaffected.

	variable (#wordlist-order)
	create (wordlist-context) $16 cells allot

	: get-order ( -- wid1 ... widn n )
		(#wordlist-order) @ 0 ?do
			(#wordlist-order) @ i -
			1- cells
			(wordlist-context) + @
		loop
		(#wordlist-order) @
	;

\ https://forth-standard.org/standard/search/SET-ORDER
\
\ Set the search order to the word lists identified by widn ... wid1.
\ Subsequently, word list wid1 will be searched first, and word list widn
\ searched last. If n is zero, empty the search order. If n is minus one,
\ set the search order to the implementation-defined minimum search order.
\ The minimum search order shall include the words FORTH-WORDLIST and
\ SET-ORDER. A system shall allow n to be at least eight.

	: set-order ( wid1 ... widn n -0 )
		dup -1 = if
			drop 		\ TODO: push system default word lists and n
		then
		dup (#wordlist-order) !

		0 ?do
			i cells
			(wordlist-context) + !
		loop
	;

\ https://forth-standard.org/standard/search/SET-CURRENT
\
\ Set the compilation word list to the word list identified by wid.

	: set-current ( wid -- ) (wordlist-current) @ ! ;

\ https://forth-standard.org/standard/search/ONLY
\
\ Set the search order to the implementation-defined minimum search order. The
\ minimum search order shall include the words FORTH-WORDLIST and SET-ORDER.

	: only ( -- ) -1 set-order ;

\ https://forth-standard.org/standard/search/SEARCH-WORDLIST
\
\ Find the definition identified by the string c-addr u in the word list
\ identified by wid. If the definition is not found, return zero. If the
\ definition is found, return its execution token xt and one (1) if the
\ definition is immediate, minus-one (-1) otherwise.

	: search-wordlist ( c-addr u wid -- 0 | xt 1 | xt -1 )
		(lookup-search-xt) ?dup if	( c-addr u wid -- xt )
			dup (xt>flags@)			( xt -- xt flags )

			\ immediate? flag = 1
			(flg-set-imm) and if 1 else -1 then
		then
	;
