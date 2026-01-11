\ https://forth-standard.org/standard/string/COMPARE

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
\ currently there are no environment flags specifed, so
\ any query will return false by default (with stack removal)
\
\ TODO There are certainly useful and supported values, see
\ https://forth-standard.org/standard/usage#usage:env

	: environment? ( c-addr u -- f ) 2drop 0 ;

\ https://forth-standard.org/standard/tools/BracketELSE

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

	: [IF] ( flag -- )
		0= if postpone [ELSE] then
	; immediate

\ https://forth-standard.org/standard/tools/BracketTHEN

	: [THEN] ( -- ) ; immediate
