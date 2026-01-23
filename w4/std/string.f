require loops.f
require parse.f
require stack.f

\ https://forth-standard.org/standard/core/BL
\
\ char is the character value for a space.

	#32 constant bl

\ https://forth-standard.org/standard/string/BLANK
\
\ If u is greater than zero, store the character value for space in u
\ consecutive character positions beginning at c-addr.

	: blank ( c-addr u -- ) bl fill ;

\ https://forth-standard.org/standard/core/CHARS
\
\ n2 is the size in address units of n1 characters.

	: chars ( n1 -- n2 ) ; \ noop, char = 1 byte in size

\ https://forth-standard.org/standard/core/CHARPlus
\
\ Add the size in address units of a character to c-addr1, giving c-addr2.

	: char+ ( a-addr2 -- a-addr2 ) 1+ ;

\ https://forth-standard.org/standard/string/SLITERAL
\
\ Append the run-time semantics given below to the current definition.
\
\ At runtime: Return c-addr2 u describing a string consisting of the characters
\ specified by c-addr1 u during compilation. A program shall not alter the returned string.

	: string, ( c-addr u -- )
		\ Compiles the c-addr u on tos, into a stable buffer and then
		\ compile the resulting address & length into the target body
		\ for use at runtime
		dup >r 			( c-addr u -- c-addr u ) ( r: -- u )
		here >r 		( c-addr u -- c-addr u ) ( r: u -- u dst )
		dup allot 		( c-addr u -- c-addr u ) ( r: u dst )		\ reserve u bytes, keep u for copy
		r@ swap 		( c-addr u -- c-addr dst u ) ( r: u dst )
		cmove			( c-addr dst u -- ) ( r: u dst ) \ copy u bytes: (src dst u)
		r> lit,			( -- ) ( r: u dst -- u )
		r> lit,			( -- ) ( r: u -- )
	;

	: sliteral ( c-addr u -- ) string, ; immediate

\ https://forth-standard.org/standard/string/DivSTRING
\
\ Adjust the character string at c-addr1 by n characters. The resulting
\ character string, specified by c-addr2 u2, begins at c-addr1 plus n
\ characters and is u1 minus n characters long.

	: /string ( c-addr u n -- c-addr' u' )
		tuck - 		( c-addr u n -- c-addr n u' )
		>r chars + 	( c-addr n u' -- c-addr' ) ( r: -- u' )
		r> 			( c-addr' -- c-addr' u' ) ( r: u' -- )
	;

\ https://forth-standard.org/standard/string/MinusTRAILING
\
\ If u1 is greater than zero, u2 is equal to u1 less the number of spaces
\ at the end of the character string specified by c-addr u1. If u1 is zero
\ or the entire string consists of spaces, u2 is zero.

	: -trailing ( c-addr u1 -- c-addr u2 )
		begin
			dup 0> if
				2dup + 1- c@ bl =	\ last char is space?
			else false then
		while
			1-
		repeat
	;

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

	: (compare-value) ( x1 x2 -- -1|0|1 ) - dup if 0< 1 or then ;

	: compare ( a1 u1 a2 u2 -- -1|0|1 )
		rot 2dup swap				( a1 u1 a2 u2 -- a1 a2 u2 u1 u1 u2 )
		(compare-value) >r			\ precompute length compare result
		min ?dup if
			0 do
				over c@
				over c@
				(compare-value) ?dup if
					2nip unloop
					r-drop
					exit
				then
				1+ swap
				1+ swap
			loop
		then

		2drop
		r>
	;

\ https://forth-standard.org/standard/string/SEARCH
\
\ Search the string specified by c-addr1 u1 for the string specified by
\ c-addr2 u2. If flag is true, a match was found at c-addr3 with u3
\ characters remaining. If flag is false there was no match and c-addr3
\ is c-addr1 and u3 is u1.

	2variable (search-pat)   \ c-addr2 u2
	2variable (search-orig)  \ c-addr1 u1

	: search ( c1 u1 c2 u2 -- c3 u3 flag )
		2dup  (search-pat) 2!		\ save pattern
		2over (search-orig) 2!		\ save original haystack

		dup 0= if					\ empty pattern => match immediately
			2drop					\ drop c2 u2
			true exit 				\ return c1 u1 -1
		then

		2drop						\ drop c2 u2, keep c1 u1 as working haystack

		begin
			\ u1 >= u2 ?
			dup (search-pat) 2@ nip u< 0=
		while
			\ compare (c1, u2) with (c2, u2)
			over (search-pat) 2@ nip	\ c1 u1 c1 u2
			(search-pat) 2@				\ c1 u1 c1 u2 c2 u2
			compare 0= if
				true exit				\ found: return current c1 u1 -1
			then

			1 /string					\ advance 1 char in haystack
		repeat

		\ not found: return original haystack
		2drop
		(search-orig) 2@
		false
	;

\ https://forth-standard.org/standard/string/UNESCAPE
\
\ Replace each `%' character in the input string c-addr1 u1 by two `%'
\ characters. The output is represented by c-addr2 u2. The buffer at
\ c-addr2 shall be big enough to hold the unescaped string. An ambiguous
\ condition occurs if the resulting string will not fit into the destination
\ buffer (c-addr2).

	: unescape ( c-addr1 u1 c-addr2 -- c-addr2 u2 )
		dup 2swap over + swap ?do
			i c@ '%' = if
				'%' over c! 1+
			then
			i c@ over c! 1+
		loop
		over -
	;
