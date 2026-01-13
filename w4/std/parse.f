require compile.f
require loops.f
require memory.f

\ https://forth-standard.org/standard/file/INCLUDE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of INCLUDED.

	: include ( i * x "name" -- j * x ) parse-name included	;

\ https://forth-standard.org/standard/core/WORD
\
\ Skip leading delimiters. Parse characters ccc delimited by char. An
\ ambiguous condition exists if the length of the parsed string is greater
\ than the implementation-defined length of a counted string.
\
\ c-addr is the address of a transient region containing the parsed word as a
\ counted string. If the parse area was empty or contained no characters other
\ than the delimiter, the resulting string has a zero length. A program may
\ replace characters within the string.

	create (word-tmp-buf) 256 allot

	: word ( char "<chars>ccc<char>" -- c-addr )
		parse                         ( c-addr u )
		dup $ff and swap drop         ( c-addr u' )

		(word-tmp-buf) >r             ( c-addr u' ) ( r: dst )
		dup r@ c!                     ( c-addr u' )        \ store count
		r@ 1+ swap cmove              ( -- )                \ copy chars
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

	: find ( c-addr -- c-addr 0 | xt 1 | xt -1 )
		dup >r
		count find-name              \ nt | 0
		dup 0= if
			drop
			r> 0
		else
			r> drop
			name>xt                    \ xt
			dup not-immediate?		\ -1 if not immediate, 0 if immediate
			-1 1 select                \ -1 normal, 1 immediate
		then
	;
