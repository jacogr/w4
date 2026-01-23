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

\ https://forth-standard.org/standard/search/SEARCH-WORDLIST
\
\ Find the definition identified by the string c-addr u in the word list
\ identified by wid. If the definition is not found, return zero. If the
\ definition is found, return its execution token xt and one (1) if the
\ definition is immediate, minus-one (-1) otherwise.

	: search-wordlist ( c-addr u wid -- 0 | xt 1 | xt -1 )
		(lookup-search-xt) dup if	( c-addr u wid -- xt )
			dup (xt>flags@)			( xt -- xt flags )

			\ immediate? flag = 1
			(flg-is-imm) and if 1 else -1 then
		then
	;

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
		dup -1 = if drop then

		dup (#wordlist-order) !

		0 ?do
			i cells
			(wordlist-context) + !
		loop
	;

\ https://forth-standard.org/standard/search/FORTH-WORDLIST
\
\ Return wid, the identifier of the word list that includes all standard words
\ provided by the implementation. This word list is initially the compilation
\ word list and is part of the initial search order.

	: forth-wordlist ( -- wid ) (dict^) ;

\ https://forth-standard.org/standard/search/FORTH
\
\ Transform the search order consisting of widn, ... wid2, wid1 (where wid1 is
\ searched first) into widn, ... wid2, widFORTH-WORDLIST.

	: (wordlist) ( wid "<name>" -- ; )
		create ,
		does>
			@ >r
			get-order nip
			r> swap set-order
		;

	\ setup

	forth-wordlist (wordlist) forth
	forth-wordlist 1 set-order

\ https://forth-standard.org/standard/search/GET-CURRENT
\
\ Return wid, the identifier of the compilation word list.

	variable (wordlist-current) forth-wordlist (wordlist-current) !

	: get-current ( -- wid ) (wordlist-current) @ ;

\ https://forth-standard.org/standard/search/SET-CURRENT
\
\ Set the compilation word list to the word list identified by wid.

	: set-current ( wid -- ) (wordlist-current) @ ! ;

\ https://forth-standard.org/standard/search/ONLY
\
\ Set the search order to the implementation-defined minimum search order. The
\ minimum search order shall include the words FORTH-WORDLIST and SET-ORDER.

	: only ( -- ) -1 set-order ;

\ https://forth-standard.org/standard/search/ALSO
\
\ Transform the search order consisting of widn, ... wid2, wid1 (where wid1
\ is searched first) into widn, ... wid2, wid1, wid1. An ambiguous condition
\ exists if there are too many word lists in the search order.

	: also ( -- ) get-order over swap 1+ set-order ;

\ https://forth-standard.org/standard/search/DEFINITIONS
\
\ Make the compilation word list the same as the first word list in the search
\ order. Specifies that the names of subsequent definitions will be placed in
\ the compilation word list. Subsequent changes in the search order will not
\ affect the compilation word list.

	\ Drop u+1 stack items
	: (definitions-discard) ( x1 ... xn u -- ) 0 ?do drop loop ;

	: definitions ( -- ) get-order swap set-current (definitions-discard) ;

\ https://forth-standard.org/standard/search/FIND
\
\ Extend the semantics of 6.1.1550 FIND to be: ( c-addr -- c-addr 0 | xt 1 | xt -1 )
\
\ Find the definition named in the counted string at c-addr. If the definition
\ is not found after searching all the word lists in the search order, return
\ c-addr and zero. If the definition is found, return xt. If the definition is
\ immediate, also return one (1); otherwise also return minus-one (-1). For a
\ given string, the values returned by FIND while compiling may differ from
\ those returned while not compiling.

\ FIXME These fail some of the standard tests, which is weird since above we
\ have set the default wordlist (without that even more fail)

	\ : find ( c-addr -- c-addr 0 | xt 1 | xt -1 )
	\ 	0								( c-addr 0 )
	\ 	(#wordlist-order) @
	\ 	0 ?do
	\ 		over count					( c-addr 0 c-addr' u )
	\ 		i cells
	\ 		(wordlist-context) + @		( c-addr 0 c-addr' u wid )
	\ 		search-wordlist				( c-addr 0; 0 | w 1 | q -1 )

	\ 		?dup if						( c-addr 0; w 1 | w -1 )
	\ 			2swap 2drop
	\ 			leave					( w 1 | w -1 )
	\ 		then						( c-addr 0 )
	\ 	loop							( c-addr 0 | w 1 | w -1 )
	\ ;
