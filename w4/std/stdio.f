require wasi.f

\ https://forth-standard.org/standard/core/TYPE
\
\ If u is greater than zero, display the character string specified by
\ c-addr and u. Characters are in the display range as per the runtime
\ environment.

	: type ( c-addr u -- ) 1 iov>fd ; \ emit to stdout

\ https://forth-standard.org/standard/core/EMIT
\
\ If x is a graphic character in the implementation-defined character set,
\ display x. The effect of EMIT for all other values of x is implementation-
\ defined.
\
\ When passed a character whose character-defining bits have a value between
\ hex 20 and 7E inclusive, the corresponding standard character, specified by
\ 3.1.2.1 Graphic characters, is displayed.

	: emit ( x -- )
		$ff and			( x -- ch )
		sp@ 1			( ch -- ch c-addr 1 )
		1 iov>fd		( ch c-addr 1 -- ch ) \ emit to stdout
		drop			( ch -- )
	;

\ https://forth-standard.org/standard/core/BL
\
\ char is the character value for a space.

	#32 constant bl

\ https://forth-standard.org/standard/core/SPACE
\
\ Display one space.

	: space ( -- ) bl emit ;

\ https://forth-standard.org/standard/core/SPACES
\
\ If n is greater than zero, display n spaces.

	: spaces ?dup if 0 do space loop then ;

\ https://forth-standard.org/standard/core/CR
\
\ Cause subsequent output to appear at the beginning of the next line.

	: cr ( -- ) #10 emit ;

\ https://forth-standard.org/standard/core/KEY
\
\ Receive one character char, a member of the implementation-defined character
\ set. Keyboard events that do not correspond to such characters are discarded
\ until a valid character is received, and those events are subsequently
\ unavailable.
\
\ All standard characters can be received. Characters received by KEY are not
\ displayed.

	$1 cells buffer: (key-buf)

	: key ( -- c )
		begin
			(key-buf) 1 0 iov<fd
			1 =
		until
		(key-buf) c@
	;

\ https://forth-standard.org/standard/core/ACCEPT
\
\ Receive a string of at most +n1 characters. An ambiguous condition exists if
\ +n1 is zero or greater than 32,767. Display graphic characters as they are
\ received. A program that depends on the presence or absence of non-graphic
\ characters in the string has an environmental dependency. The editing
\ functions, if any, that the system performs in order to construct the string
\ are implementation-defined.
\
\ Input terminates when an implementation-defined line terminator is received.
\ When input terminates, nothing is appended to the string, and the display is
\ maintained in an implementation-defined way.

	: accept ( c-addr u -- u2 )
		0 					( c-addr u -- c-addr u count )
		begin
			2dup swap <		( c-addr u count -- c-addr u count flag )
		while
			key 			( c-addr u count -- c-addr u count ch )
			dup 10 =		\ lf?
			over 13 =		\ cr?
			or if 			\ lf or cr?
				drop exit	( c-addr u count ch -- c-addr u count )
			else
				sp-3@ 		( c-addr u count ch -- c-addr u count ch c-addr )
				sp-2@ 		( c-addr u count ch c-addr -- c-addr u count ch c-addr count )
				+ 			( c-addr u count ch c-addr count -- c-addr u count ch c-addr' )
				c! 			( c-addr u count ch c-addr' -- c-addr u count )
				1+ 			( c-addr u count -- c-addr u count' )
			then
		repeat
		nip nip				( c-addr u count -- count )
	;
