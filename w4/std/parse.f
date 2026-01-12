require compile.f
require loops.f
require memory.f

\ https://forth-standard.org/standard/file/INCLUDE

	: include ( i * x "name" -- j * x ) parse-name included	;

\ https://forth-standard.org/standard/core/WORD
\
\ Skip leading delimiters. Parse characters ccc delimited by char. An
\ ambiguous condition exists if the length of the parsed string is greater
\ than the implementation-defined length of a counted string.

	: word ( char "<chars>ccc<char>" -- c-addr )
		parse
		dup $ff and swap drop        ( c-addr u' )

		here >r                      ( c-addr u' )   ( r: dst )
		dup 1+ allot                 ( c-addr u' )
		dup r@ c!                    ( c-addr u' )
		r@ 1+ swap cmove             ( -- )
		r>
	;

\ https://forth-standard.org/standard/core/COUNT
\
\ Return the character string specification for the counted string
\ stored at c-addr1

	: count ( c-addr1 -- c-addr2 u )
		dup c@ 		\ fetch count
		swap 1+ 	\ point to first char
		swap
	;

\ https://forth-standard.org/standard/core/FIND
\
\ Find the definition named in the counted string at c-addr. If the definition
\ is not found, return c-addr and zero. If the definition is found, return its
\ execution token xt. If the definition is immediate, also return one (1),
\ otherwise also return minus-one (-1).
\
\ TODO Factor out the flag test between here and name>compile

	: find ( c-addr -- c-addr 0 | xt 1 | xt -1 )
		dup >r                 \ save original counted-string address
		count find-name        \ -> c-addr' u -> nt | 0
		dup 0= if              \ not found
			drop
			r> 0
			exit
		then
		r> drop                \ discard original c-addr
		name>xt                \ nt -> xt
		dup >flags @ $02 and if
			1                    \ immediate
		else
			-1                   \ normal
		then
	;

