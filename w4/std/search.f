require constants.f
require loops.f
require stack.f
require text.f

require ../ext/list.f

\ https://forth-standard.org/standard/search/WORDLIST
\
\ Create a new empty word list, returning its word list identifier wid.
\ The new word list may be returned from a pool of preallocated word lists
\ or may be dynamically allocated in data space. A system shall allow the
\ creation of at least 8 new word lists in addition to any provided as part
\ of the system.

	: WORDLIST ( -- wid ) (new-lookup-large) ;

\ https://forth-standard.org/standard/search/SEARCH-WORDLIST
\
\ Find the definition identified by the string c-addr u in the word list
\ identified by wid. If the definition is not found, return zero. If the
\ definition is found, return its execution token xt and one (1) if the
\ definition is immediate, minus-one (-1) otherwise.

	: SEARCH-WORDLIST ( c-addr u wid -- 0 | xt 1 | xt -1 )
		(lookup-search-xt) dup if	( c-addr u wid -- xt|0 )
			\ immediate? set flag = 1
			dup is-xt-immediate?	( xt -- xt f )
			1 -1 select				( xt f -- xt -1|1 )
		then
	;

\ https://forth-standard.org/standard/search/GET-ORDER
\
\ Returns the number of word lists n in the search order and the word list
\ identifiers widn ... wid1 identifying these word lists. wid1 identifies
\ the word list that is searched first, and widn the word list that is
\ searched last. The search order is unaffected.

	$16 constant (wordlists-max) \ TODO check pushes against this

	: GET-ORDER ( -- wid1 ... widn n )
		(wid-count) 0 ?do
			(wid-count) i -
			1- cells
			(wid-list) + @
		loop

		(wid-count)
	;

\ https://forth-standard.org/standard/search/SET-ORDER
\
\ Set the search order to the word lists identified by widn ... wid1.
\ Subsequently, word list wid1 will be searched first, and word list widn
\ searched last. If n is zero, empty the search order. If n is minus one,
\ set the search order to the implementation-defined minimum search order.
\ The minimum search order shall include the words FORTH-WORDLIST and
\ SET-ORDER. A system shall allow n to be at least eight.

	: SET-ORDER ( wid1 ... widn n -0 )
		dup -1 = if
			drop
			forth-wordlist 1 recurse
        	exit
		then

		dup (wid-count!)

		0 ?do
			i cells
			(wid-list) + !
		loop
	;

\ https://forth-standard.org/standard/search/ORDER
\
\ Display the word lists in the search order in their search order
\ sequence, from first searched to last searched. Also display the
\ word list into which new definitions will be placed. The display
\ format is implementation dependent.

	: ORDER ( -- )
		base @							( -- base )
		decimal

		(wid-count) u.

		hex

		(wid-count) 0 ?do
			(wid-count) i -
			1- cells
			(wid-list) + @
			9 u.r
		loop

		base !							( base -- )
	;

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

	forth-wordlist (wordlist) FORTH

\ https://forth-standard.org/standard/search/GET-CURRENT
\
\ Return wid, the identifier of the compilation word list.

	: GET-CURRENT ( -- wid ) (wid-curr) ;

\ https://forth-standard.org/standard/search/SET-CURRENT
\
\ Set the compilation word list to the word list identified by wid.

	: SET-CURRENT ( wid -- ) (wid-curr!) ;

\ https://forth-standard.org/standard/search/ONLY
\
\ Set the search order to the implementation-defined minimum search order. The
\ minimum search order shall include the words FORTH-WORDLIST and SET-ORDER.

	: ONLY ( -- ) -1 set-order ;

\ https://forth-standard.org/standard/search/ALSO
\
\ Transform the search order consisting of widn, ... wid2, wid1 (where wid1
\ is searched first) into widn, ... wid2, wid1, wid1. An ambiguous condition
\ exists if there are too many word lists in the search order.

	: ALSO ( -- ) get-order over swap 1+ set-order ;

\ https://forth-standard.org/standard/search/DEFINITIONS
\
\ Make the compilation word list the same as the first word list in the search
\ order. Specifies that the names of subsequent definitions will be placed in
\ the compilation word list. Subsequent changes in the search order will not
\ affect the compilation word list.

	: DEFINITIONS ( -- ) get-order over set-current set-order ;

\ https://forth-standard.org/standard/search/PREVIOUS
\
\ Transform the search order consisting of widn, ... wid2, wid1 (where wid1
\ is searched first) into widn, ... wid2. An ambiguous condition exists if
\ the search order was empty before PREVIOUS was executed.

	: PREVIOUS ( -- ) get-order nip 1- set-order ;

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
\
\ NOTE the `FIND` in parse.f already uses `find-name` internally which searches
\ both the locals-wid and the wordlists. Until we get to untangle `find-name`,
\ this doesn't actually add any new functionality.

	: FIND ( c-addr -- c-addr 0 | xt 1 | xt -1 )
		0								( c-addr 0 )

		\ search locals word list (if available)
		(locals-wid) ?dup if
			over count rot				( c-addr 0 wid -- c-addr 0 c-addr' u wid )
			search-wordlist				( c-addr 0; 0 | w 1 | q -1 )

			?dup if						( c-addr 0; w 1 | w -1 )
				2swap 2drop
				exit
			then
		then

		\ search all available wordlists
		(wid-count) 0 ?do
			over count					( c-addr 0 c-addr' u )
			i cells
			(wid-list) + @				( c-addr 0 c-addr' u wid )
			search-wordlist				( c-addr 0; 0 | w 1 | q -1 )

			?dup if						( c-addr 0; w 1 | w -1 )
				2swap 2drop
				leave					( w 1 | w -1 )
			then						( c-addr 0 )
		loop							( c-addr 0 | w 1 | w -1 )
	;

\ setup, make it usable via the standard init string

	only forth definitions		\ setup initial search order
