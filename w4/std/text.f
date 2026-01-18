require compile.f
require constants.f
require logic.number.f
require math.f
require memory.f
require parse.f
require stack.f
require stack.loop.f
require wasi.f

\ https://forth-standard.org/standard/core/DECIMAL
\
\ Set the numeric conversion radix to ten (decimal).

	: decimal ( -- ) #10 base ! ;

\ https://forth-standard.org/standard/core/HEX
\
\ Set contents of BASE to sixteen.

	: hex ( -- ) $10 base ! ;

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
		parse-name			( -- c-addr u )   	   \ parse the name/next
		0= #-12 and throw	( c-addr u -- c-addr )
		c@					( c-addr -- char )  \ retrieve the first char
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

	$ff constant (#max-off) 			\ 255 max string size
	variable (#tmp-off)					\ offset for pictured buffer

	(#max-off) 1+ buffer: (#tmp-buf)	\ pictured buffer

	: hold ( char -- )
		(#tmp-off) @		\ get offset
		(#tmp-buf) + c! 	\ store char at offset
		(#tmp-off) @ 1-		\ decrement offset
		(#tmp-off) !		\ store offset
	;

\ https://forth-standard.org/standard/core/HOLDS
\
\ Adds the string represented by c-addr u to the pictured numeric output
\ string. An ambiguous condition exists if HOLDS executes outside of a
\ <# #> delimited number conversion.

	: holds ( addr u -- )
		begin dup while
			1- 2dup + c@ hold
		repeat
		2drop
	;

\ https://forth-standard.org/standard/core/SIGN
\
\ If n is negative, add a minus sign to the beginning of the pictured
\ numeric output string.

	: sign ( n -- ) 0< if '-' hold then ;

\ https://forth-standard.org/standard/core/num-start
\
\ Initialize the pictured numeric output conversion process.

	: (#len) ( -- n ) (#max-off) (#tmp-off) @ - ;

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

	: <# ( -- ) (#max-off) (#tmp-off) ! ; \ 0...255 (256 max-len)

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
		2drop				( xd -- )
		(#tmp-off) @ 1+		( -- off+1 )
		(#tmp-buf) +		( off+1 -- c-addr )
		(#len)				( c-addr -- c-addr u )
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
			swap			( n1 n2 -- n2 n1 )
			dup >r 			( n2 n1 -- n2 n1 )          ( r: -- n1 )

			\ make unsigned magnitude as a DOUBLE, safely (works for MIN-INT)
			s>d  			( n2 n1 -- n2 lo hi )
			r@ 0< if 		( n2 lo hi -- n2 lo hi )    \ was original n1 negative?
				dnegate 	( n2 lo hi -- n2 lo' hi' )  \ magnitude
			then

			#s 				( n2 lo hi -- n2 0 0 )
			r> sign			( n2 0 0 -- n2 0 0 )        \ may HOLD '-'
			(#pad)			( n2 0 0 -- 0 0 )
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

\ https://forth-standard.org/standard/core/Cq
\
\ Interpretation semantics for this word are undefined.
\
\ Parse ccc delimited by " (double-quote) and append the run-time semantics
\ given below to the current definition.
\
\ At runtime: Return c-addr, a counted string consisting of the characters ccc.
\ A program shall not alter the returned string.;

	: cstring, ( c-addr u -- )
		here >r 			( c-addr u ) ( r: dst )
		dup 1+ allot 		( c-addr u )       \ reserve u+1 bytes
		dup r@ c!			( c-addr u )       \ store count byte = u at dst
		r@ 1+ swap cmove 	( -- )             \ copy chars to dst+1
		r> lit,				( -- )
	;

	: (c") ( "input<quote>" -- c-addr ) '"' parse state @ if cstring, then ;

	: c" ( "input<quote>" -- c-addr ) (c") ; immediate

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

	: (type-cr) type cr ;

	: .( ( "ccc<paren>" -- ) ')' ['] (type-cr) (parse-multi) ; immediate

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

\ https://forth-standard.org/standard/core/Seq
\
\ Parse ccc delimited by " (double-quote), using the translation rules below.
\ Append the run-time semantics given below to the current definition.
\
\ implementation from original proposal:
\ http://www.forth200x.org/escaped-strings.html

	create (s"\-result)
		#256 #1 chars + allot                   \ 256 + count byte

	create (s"\-escapetable)
		 #7 c,    \ \a bel
		 #8 c,    \ \b bs
		'c' c,    \ \c
		'd' c,    \ \d
		#27 c,    \ \e esc
		#12 c,    \ \f ff
		'g' c,    \ \g
		'h' c,    \ \h
		'i' c,    \ \i
		'j' c,    \ \j
		'k' c,    \ \k
		#10 c,    \ \l lf
		'm' c,    \ \m  (note: handled specially below)
		#10 c,    \ \n  (unix lf; \n handled specially below)
		'o' c,    \ \o
		'p' c,    \ \p
		'"' c,    \ \q  => "
		#13 c,    \ \r cr
		's' c,    \ \s
		 #9 c,    \ \t ht
		'u' c,    \ \u
		#11 c,    \ \v vt
		'w' c,    \ \w
		'x' c,    \ \x  (note: handled specially below)
		'y' c,    \ \y
		 #0 c,    \ \z nul

	create (s"\-crlf)
		#2 c,  #13 c,  #10 c,

	: (s"\-addchar) ( char $dest -- )
		tuck count + c!
		#1 swap c+!
	;

	: (s"\-append) ( c-addr u $dest -- )
		>r
		tuck r@ count + swap cmove
		r> c+!
	;

	: (s"\-extractnum)
		base @ >r  base !
		0 0 2swap >number 2swap drop
		r> base !
	;

	: (s"\-addescape) ( c-addr len dest -- c-addr' len' )
		over 0<> if
			>r		( r: -- dest )

			\ octal?
			over c@ '0' '8' within if \ '0' .. '7' + 1
				8 (s"\-extractnum)
				r> (s"\-addchar)
			else
				\ hex?
				over c@ 'x' = if
					1 /string
					>r 2 #16 (s"\-extractnum) nip
					r> 2 - swap
					r> (s"\-addchar)
				else
					\ crlf?
					over c@ 'm' = if
						1 /string #13 r@ (s"\-addchar) #10
						r> (s"\-addchar)
					else
						\ crlf?
						over c@ 'n' = if
							1 /string (s"\-crlf) count
							r> (s"\-append)
						else
							\ a..z?
							over c@ 'a' '{' within if \ 'a' .. 'z' + 1
								over c@ [char] a - (s"\-escapetable) +
							else
								over
							then

							c@
							r> (s"\-addchar)
							1 /string
						then
					then
				then
			then
		else drop then
	;

	: (s"\-parse) ( c-addr len dest -- c-addr' len' )
		dup >r 0 swap c!

		begin
			dup
		while
			over c@ '"' <>
		while
			over c@ '\' = if
				#1 /string r@ (s"\-addescape)
			else
				over c@ r@ (s"\-addchar) #1 /string
			then
		repeat then

		dup if #1 /string then
		r> drop
	;

	: (s"\-readescaped) ( "ccc" -- c-addr )
		source >in @ /string tuck
  		(s"\-result) dup >r (s"\-parse)
  		nip - >in +! r>
	;

	: s\"
		(s"\-readescaped) count
		state @ if
			string,
		then
	; immediate
