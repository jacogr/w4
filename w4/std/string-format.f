m4_require_w4(`std/compile.f')
m4_require_w4(`std/constants.f')
m4_require_w4(`std/logic-number.f')
m4_require_w4(`std/math.f')
m4_require_w4(`std/memory.f')
m4_require_w4(`std/parse.f')
m4_require_w4(`std/stack.f')
m4_require_w4(`std/stack-control.f')
m4_require_w4(`std/stdio.f')

\ https://forth-standard.org/standard/core/DECIMAL
\
\ Set the numeric conversion radix to ten (decimal).

	: DECIMAL ( -- ) #10 base ! ;

\ https://forth-standard.org/standard/core/HEX
\
\ Set contents of BASE to sixteen.

	: HEX ( -- ) $10 base ! ;

\ https://forth-standard.org/standard/core/CHAR
\
\ Skip leading space delimiters. Parse name delimited by a space. Put the
\ value of its first character onto the stack.

	: CHAR ( "<spaces>name" -- char )
		parse-name			( -- c-addr u )   	   \ parse the name/next

		\ -12	argument type mismatch
		0= #-12 and throw	( c-addr u -- c-addr )

		c@					( c-addr -- char )  \ retrieve the first char
	;

\ https://forth-standard.org/standard/core/BracketCHAR
\
\ Skip leading space delimiters. Parse name delimited by a space. Append the
\ run-time semantics given below to the current definition.
\
\ At runtime: Place char, the value of the first character name, on the stack.

	: [CHAR] ( -- ) char postpone literal ; immediate

\ https://forth-standard.org/standard/core/HOLD
\
\ Add char to the beginning of the pictured numeric output string.

	string-max 1- constant (#max-off) 	\ 255 max offset size
	variable (#tmp-off)					\ offset for pictured buffer

	string-max 1+ buffer: (#tmp-buf)		\ pictured buffer

	: HOLD ( char -- )
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

	: HOLDS ( addr u -- )
		begin dup while
			1- 2dup + c@ hold
		repeat
		2drop
	;

\ https://forth-standard.org/standard/core/SIGN
\
\ If n is negative, add a minus sign to the beginning of the pictured
\ numeric output string.

	: SIGN ( n -- ) 0< if '-' hold then ;

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
		base @ ud/mod		\ rem qlo qhi
		>r					\ rem qlo    R: qhi
		swap (#chr) hold	\ qlo
		r>					\ qlo qhi    (ud')
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

	: U.R ( u1 n -- )
		<#
			(u.r)
		#> type space
	;

	: U.RD ( u1 n -- )
		<#
			'.' hold
			(u.r)
		#> type space
	;

\ https://forth-standard.org/standard/core/Ud
\
\ Display u in free field format.

	: U. ( u -- ) 0 u.r ;

\ https://forth-standard.org/standard/core/DotR
\
\ Display n1 right aligned in a field n2 characters wide. If the number
\ of characters required to display n1 is greater than n2, all digits are
\ displayed with no leading spaces in a field as wide as necessary.

	: .R ( n1 n2 -- )
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

\ https://forth-standard.org/standard/double/DDotR
\
\ display d right aligned in a field n characters wide

	: D.R ( lo hi n -- )
		<#
			>r 					\ r: n
			2dup d0< >r 		\ r: n neg?
			r@ if dnegate then	\ magnitude as ud (safe for min-2int)
			#s					\ -> 0 0
			r> if '-' hold then	\ apply sign
			r> rot rot (#pad)	\ reorder: 0 0 n -> n 0 0
		#> type space
	;

\ https://forth-standard.org/standard/double/DDot
\
\ display d in free field format

	: D. ( lo hi -- ) 0 d.r ;

\ https://forth-standard.org/standard/core/Sq
\
\ Parse ccc delimited by " (double-quote). Append the run-time semantics
\ given below to the current definition.
\
\ At runtime: Return c-addr and u describing a string consisting of the
\ characters ccc. A program shall not alter the returned string.

	: (s") ( "input<quote>" -- c-addr u ) '"' parse state @ if string, then ;

	: S" ( "input<quote>" -- c-addr u ) (s") ; immediate

\ https://forth-standard.org/standard/core/Cq
\
\ Interpretation semantics for this word are undefined.
\
\ Parse ccc delimited by " (double-quote) and append the run-time semantics
\ given below to the current definition.
\
\ At runtime: Return c-addr, a counted string consisting of the characters ccc.
\ A program shall not alter the returned string.;

	: CSTRING, ( c-addr u -- )
		here 					( c-addr u -- c-addr u dst )
		swap dup 1+ allot 		( c-addr u dst -- c-addr dst u )
		swap (place-result)		( c-addr dst u -- dst )
		lit,					\ compile address
	;

	: (c") ( "input<quote>" -- c-addr ) '"' parse state @ if cstring, then ;

	: C" ( "input<quote>" -- c-addr ) (c") ; immediate

\ https://forth-standard.org/standard/core/Dotq
\
\ Parse ccc delimited by " (double-quote). Append the run-time semantics
\ given below to the current definition.
\
\ At runtime: display the string

	: ." ( "input<quote>" -- ) (s") state @ if postpone type else type then ; immediate

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

	: >DIGIT ( char -- +n true | 0 ) \ "to-digit"
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

		dup base @ < dup 0= if nip then ( ... -- +n true | false ) \ reject beyond base
	;

	: >NUMBER ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 ) \ "to-number"
		2swap 2>r

		begin ( ud1 c-addr1 u1 -- c-addr u ) ( r: -- ud.accum )
			dup while \ character left to inspect
				over c@ >digit
			while \ digit parsed within base
				2r> base @ 1 m*/ ( c-addr u -- c-addr u n.digit ud.accum ) \ scale accum by base
				rot m+ 2>r \ add current digit to accum
				1 /string ( c-addr u -- c-addr1+1 u1-1 )
		repeat then

		2r> 2swap ( c-addr2 u2 -- ud2 c-addr2 u2 ) ( r: ud2 -- )
	;
