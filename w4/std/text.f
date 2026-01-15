require compile.f
require constants.f
require math.f
require memory.f
require parse.f
require stack.f
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

\ https://forth-standard.org/standard/core/KEY
\
\ Receive one character char, a member of the implementation-defined character
\ set. Keyboard events that do not correspond to such characters are discarded
\ until a valid character is received, and those events are subsequently
\ unavailable.
\
\ All standard characters can be received. Characters received by KEY are not
\ displayed.

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

	: (accept) ( c-addr u -- c-addr u u2 )
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
	;

	: accept ( c-addr u -- u2 )
		(accept)	( c-addr u -- c-addr u count )
		nip nip		( c-addr u count -- count )
	;

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

\ https://forth-standard.org/standard/core/CHAR
\
\ Skip leading space delimiters. Parse name delimited by a space. Put the
\ value of its first character onto the stack.

	: char ( "<spaces>name" -- char )
		parse-name			( -- c-addr u )    	   \ parse the name/next
		0= #-12 and throw	( c-addr u -- c-addr )
		c@					( c-addr -- char )   \ retrieve the first char
	;

\ https://forth-standard.org/standard/core/BracketCHAR
\
\ Skip leading space delimiters. Parse name delimited by a space. Append the
\ run-time semantics given below to the current definition.
\
\ At runtime: Place char, the value of the first character name, on the stack.

	: [char] ( -- ) char postpone literal ; immediate

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

\ https://forth-standard.org/standard/core/HOLD
\
\ Add char to the beginning of the pictured numeric output string.

	$ff constant (#max) 				\ 255 max string size
	create (#-tmp-buf) (#max) 1+ allot	\ offset in first byte, #max + 1

	: hold ( char -- )
		(#-tmp-buf) @		\ get offset
		(#-tmp-buf) + c! 	\ store char at offset
		(#-tmp-buf) @ 1-	\ decrement offset
		(#-tmp-buf) !		\ store offset
	;

\ https://forth-standard.org/standard/core/SIGN
\
\ If n is negative, add a minus sign to the beginning of the pictured
\ numeric output string.

	: sign ( n -- ) 0< if '-' hold then ;

\ https://forth-standard.org/standard/core/num-start
\
\ Initialize the pictured numeric output conversion process.

	: (#len) ( -- n ) (#max) (#-tmp-buf) @ - ;

	: (#pad) ( n ud -- ud' )
		base @ #16 = if '$' hold else base @ #2 = if '%' hold then then
		2>r
		(#len) -
		dup 0> if 0 do bl hold loop else drop then
		2r>
	;

	\ standard uppercase version
	: (#chr) ( n -- char ) dup #9 > #7 and + '0' + ; \  explot that 'A' - '9' = 8

	\ lowercase version, not standard, doesn't pass test suite
	\ : (#chr) ( n -- char ) dup #9 > #39 and + '0' + ; \ exploit that 'a' - '9' = 40

	: <# ( -- ) (#max) (#-tmp-buf) ! ;

\ https://forth-standard.org/standard/core/num
\
\ Divide ud1 by the number in BASE giving the quotient ud2 and the
\ remainder n. (n is the least significant digit of ud1.) Convert n
\ to external form and add the resulting character to the beginning
\ of the pictured numeric output string

	: # ( ud -- ud' )
		base @ ud/mod          \ rem qlo qhi
		>r                     \ rem qlo    R: qhi
		swap (#chr) hold       \ qlo
		r>                     \ qlo qhi    (ud')
	;

\ https://forth-standard.org/standard/core/numS
\
\ Convert one digit of ud1 according to the rule for #. Continue conversion
\ until the quotient is zero. ud2 is zero.

	: #s ( ud -- ud' ) begin # 2dup or 0= until ;

\ https://forth-standard.org/standard/core/num-end
\
\ Drop xd. Make the pictured numeric output string available as a character
\ string. c-addr and u specify the resulting character string. A program may
\ replace characters within the string.

	: #> ( xd -- c-addr u )
		2drop					( xd -- )
		(#-tmp-buf) (#-tmp-buf) @ + 1+	( -- c-addr )
		(#len)					( c-addr -- c-addr u )
	;

\ https://forth-standard.org/standard/core/UDotR
\
\ Display u right aligned in a field n characters wide. If the number
\ of characters required to display u is greater than n, all digits are
\ displayed with no leading spaces in a field as wide as necessary.

	: (u.r) swap 0 #s (#pad) ;

	: u.r ( u1 n -- )
		<#
			(u.r)
		#> type space
	;

	: u.rd ( u1 n -- )
		<#
			'.' hold
			(u.r)
		#> type space
	;

\ https://forth-standard.org/standard/core/Ud
\
\ Display u in free field format.

	: u. ( u -- ) 0 u.r ;

\ https://forth-standard.org/standard/core/DotR
\
\ Display n1 right aligned in a field n2 characters wide. If the number
\ of characters required to display n1 is greater than n2, all digits are
\ displayed with no leading spaces in a field as wide as necessary.

	: .r ( n1 n2 -- )
		<#
			swap            \ n2 n1
			dup >r          \ n2 n1        R: n1
			abs s>d         \ n2 lo hi
			#s              \ n2 lo hi
			r> sign         \ n2 lo hi     (sign consumes n1, may HOLD '-')
			(#pad)          \ lo hi
		#> type space
	;

\ https://forth-standard.org/standard/core/d
\
\ Display n in free field format.

	: . ( n -- ) 0 .r ;

\ https://forth-standard.org/standard/core/Sq
\
\ Parse ccc delimited by " (double-quote). Append the run-time semantics
\ given below to the current definition.
\
\ At runtime: Return c-addr and u describing a string consisting of the
\ characters ccc. A program shall not alter the returned string.

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

	: (s") ( "input<quote>" -- c-addr u ) '"' parse state @ if string, then ;

	: s" ( "input<quote>" -- c-addr u ) (s") ; immediate

\ https://forth-standard.org/standard/core/Dotq
\
\ Parse ccc delimited by " (double-quote). Append the run-time semantics
\ given below to the current definition.
\
\ At runtime: display the string

	: ." ( "input<quote>" -- ) (s") state @ if postpone type else type then ; immediate

\ https://forth-standard.org/standard/core/Dotp
\
\ Parse and display ccc delimited by ) (right parenthesis). .( is an
\ immediate word.

	: .( ( "ccc<paren>" -- ) ')' parse type ; immediate

\ https://forth-standard.org/standard/core/toNUMBER
\
\ ud2 is the unsigned result of converting the characters within the string
\ specified by c-addr1 u1 into digits, using the number in base, and adding
\ each into ud1 after multiplying ud1 by the number in base. Conversion
\ continues left-to-right until a character that is not convertible, including
\ any "+" or "-", is encountered or the string is entirely converted. c-addr2
\ is the location of the first unconverted character or the first character
\ past the end of the string if the string was entirely converted. u2 is the
\ number of unconverted characters in the string. An ambiguous condition exists
\ if ud2 overflows during the conversion.

	: >digit ( char -- +n true | 0 ) \ "to-digit"
		\ convert char to a digit according to base followed by true, or false if out of range
		dup [ '9' 1+ ] literal <
		if '0' - \ convert '0'-'9'
			dup 0< if drop 0 exit then \ reject < '0'
		else
			bl or \ convert to lowercase, exploiting ASCII
			'a' -
			dup 0< if drop 0 exit then \ reject non-letter < 'a'
			#10 + \ convert 'a'-'z'
		then
		dup base @ < dup 0= if nip then ( +n true | false ) \ reject beyond base
	;

	: >number ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 ) \ "to-number"
		2swap 2>r
		begin ( c-addr u ) ( R: ud.accum )
			dup while \ character left to inspect
				over c@ >digit
			while \ digit parsed within base
				2r> base @ 1 m*/ ( c-addr u n.digit ud.accum ) \ scale accum by base
				rot m+ 2>r \ add current digit to accum
				1 /string ( c-addr1+1 u1-1 )
		repeat then
		2r> 2swap ( ud2 c-addr2 u2 )
	;
