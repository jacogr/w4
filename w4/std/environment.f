\ https://forth-standard.org/standard/string/COMPARE
\
\ Compare the string specified by c-addr1 u1 to the string specified by
\ c-addr2 u2. The strings are compared, beginning at the given addresses,
\ character by character, up to the length of the shorter string or until
\ a difference is found. If the two strings are identical, n is zero.
\
\ If the two strings are identical up to the length of the shorter string,
\ n is minus-one (-1) if u1 is less than u2 and one (1) otherwise. If the
\ two strings are not identical up to the length of the shorter string, n is
\ minus-one (-1) if the first non-matching character in the string specified
\ by c-addr1 u1 has a lesser numeric value than the corresponding character in
\ the string specified by c-addr2 u2 and one (1) otherwise.

	: (compare) ( x1 x2 -- -1|0|1 ) - dup if 0< 1 or then ;

	: compare ( addr1 u1 addr2 u2 -- -1|0|1 )
		rot 2dup swap (compare) >r
		min ?dup if
			0 do
				count >r swap
				count r>
				(compare) ?dup if
					nip nip
					unloop
					r> drop
					exit
				then
				swap
			loop
		then
		2drop
		r>
	;

\ https://forth-standard.org/standard/core/ENVIRONMENTq
\
\ c-addr is the address of a character string and u is the string's character
\ count. u may have a value in the range from zero to an implementation-defined
\ maximum which shall not be less than 31. The character string should contain
\ a keyword from 3.2.6 Environmental queries or the optional word sets to be
\ checked for correspondence with an attribute of the present environment. If
\ the system treats the attribute as unknown, the returned flag is false;
\ otherwise, the flag is true and the i * x returned is of the type specified
\ in the table for the attribute queried.
\
\ currently there are no environment flags specifed, so
\ any query will return false by default (with stack removal)
\
\ TODO There are certainly useful and supported values, see
\ https://forth-standard.org/standard/usage#usage:env

	: environment? ( c-addr u -- f ) 2drop 0 ;

\ https://forth-standard.org/standard/tools/BracketELSE
\
\ Skipping leading spaces, parse and discard space-delimited words from the
\ parse area, including nested occurrences of [IF] ... [THEN] and [IF] ...
\ [ELSE] ... [THEN], until the word [THEN] has been parsed and discarded. If
\ the parse area becomes exhausted, it is refilled as with REFILL.

	: [ELSE] ( -- )
		1 begin                                          \ level
			begin parse-name dup while                  \ level adr len
				2dup S" [IF]" compare 0= if                  \ level adr len
					2drop 1+                                 \ level'
				else                                        \ level adr len
					2dup S" [ELSE]" compare 0= if             \ level adr len
						2drop 1- dup if 1+ then               \ level'
					else                                      \ level adr len
						S" [THEN]" compare 0= if              \ level
						1-                                 \ level'
					then
				then
			then ?dup 0= if exit then                   \ level'
		repeat 2drop refill 0= until                                   \ level
		drop
	; immediate

	\ Interesting implementation using wordlists
	\
	\ WORDLIST DUP CONSTANT BRACKET-FLOW-WL GET-CURRENT SWAP SET-CURRENT
	\ : [IF]   ( level1 -- level2 ) 1+ ;
	\ : [ELSE] ( level1 -- level2 ) DUP 1 = IF 1- THEN ;
	\ : [THEN] ( level1 -- level2 ) 1- ;
	\ SET-CURRENT

	\ : [ELSE] ( -- )
	\    1 BEGIN BEGIN PARSE-NAME DUP WHILE
	\       BRACKET-FLOW-WL SEARCH-WORDLIST IF
	\          EXECUTE DUP 0= IF DROP EXIT THEN
	\       THEN
	\    REPEAT 2DROP REFILL 0= UNTIL DROP
	\ ; IMMEDIATE

\ https://forth-standard.org/standard/tools/BracketIF
\
\ If flag is true, do nothing. Otherwise, skipping leading spaces, parse
\ and discard space-delimited words from the parse area, including nested
\ occurrences of [IF] ... [THEN] and [IF] ... [ELSE] ... [THEN], until either
\ the word [ELSE] or the word [THEN] has been parsed and discarded. If the
\ parse area becomes exhausted, it is refilled as with REFILL. [IF] is an
\ immediate word.
\
\ An ambiguous condition exists if [IF] is POSTPONEd, or if the end of the
\ input buffer is reached and cannot be refilled before the terminating [ELSE]
\ or [THEN] is parsed.

	: [IF] ( flag -- )
		0= if postpone [ELSE] then
	; immediate

\ https://forth-standard.org/standard/tools/BracketTHEN
\
\ Does nothing. [THEN] is an immediate word.

	: [THEN] ( -- ) ; immediate
