require constants.f
require loops.f
require search.f
require stack.f
require string.utils.f

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

	: ENVIRONMENT? ( c-addr u -- f )
		2dup s" #LOCALS" streq-ni 0= if 2drop (env-locals#) exit then
		2dup s" RETURN-STACK-CELLS" streq-ni 0= if 2drop (env-stackmax#) exit then
		2dup s" STACK-CELLS" streq-ni 0= if 2drop (env-stackmax#) exit then
		2dup s" WORDLISTS" streq-ni 0= if 2drop (env-wordlists-max#) exit then

		2dup s" /COUNTED-STRING" if 2drop string-max exit then
		2dup s" /HOLD" if 2drop (env-holdsize#) exit then
		2dup s" /PAD" if 2drop (env-padsize#) exit then

		2drop 0				\ default, return false
	;

\ https://forth-standard.org/standard/tools/BracketELSE
\
\ Skipping leading spaces, parse and discard space-delimited words from the
\ parse area, including nested occurrences of [IF] ... [THEN] and [IF] ...
\ [ELSE] ... [THEN], until the word [THEN] has been parsed and discarded. If
\ the parse area becomes exhausted, it is refilled as with REFILL.

	: [ELSE] ( -- )
		1 begin                                          \ level
			begin parse-name dup while                  \ level adr len
				2dup S" [IF]" streq-ni 0= if                  \ level adr len
					2drop 1+                                 \ level'
				else                                        \ level adr len
					2dup S" [ELSE]" streq-ni 0= if             \ level adr len
						2drop 1- dup if 1+ then               \ level'
					else                                      \ level adr len
						S" [THEN]" streq-ni 0= if              \ level
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
