\ https://forth-standard.org/standard/core/BL
\
\ char is the character value for a space.

	#32 constant bl

\ https://forth-standard.org/standard/core/CHARS
\
\ n2 is the size in address units of n1 characters.

	: chars ( n1 -- n2 ) ; \ noop, char = 1 byte in size

\ https://forth-standard.org/standard/core/CHARPlus
\
\ Add the size in address units of a character to c-addr1, giving c-addr2.

	: char+ ( a-addr2 -- a-addr2 ) 1+ ;

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
