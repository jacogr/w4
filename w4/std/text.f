require compile.f
require math.f
require memory.f
require parse.f
require stack.f

\ https://forth-standard.org/standard/core/TYPE

	: iov>fd ( c-addr-u u 1|2 -- ) \ 1=stdout, 2=stderr
		#2 (sp@-) 			( c-addr u 1|2 -- c-addr u 1|2 a-iov )
		1 					\ write a single iov
		(tmp^)				( c-addr u 1|2 a-iov 1 -- c-addr u 1|2 a-iov 1 a-tmp )
		wasi::fd_write		( c-addr u 1|2 a-iov 1 a-tmp -- c-addr u err )
		0<> #-37 and throw	( c-addr u err -- c-addr u )
		2drop				( c-addr u -- )
	;

	: type ( c-addr u -- ) 1 iov>fd ; \ emit to stdout

\ https://forth-standard.org/standard/core/EMIT

	: emit ( x -- )
		$ff and			( x -- ch )
		sp@ 1			( ch -- ch c-addr 1 )
		1 iov>fd		( ch c-addr 1 -- ch ) \ emit to stdout
		drop			( ch -- )
	;

\ https://forth-standard.org/standard/core/BL

	: bl ( -- char ) #32 ;

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

	: [char] ( -- ) char postpone literal ; immediate

\ https://forth-standard.org/standard/string/DivSTRING

	: /string ( c-addr u n -- c-addr' u' )
		tuck - 		( c-addr u n -- c-addr n u' )
		>r chars + 	( c-addr n u' -- c-addr' ) ( r: -- u' )
		r> 			( c-addr' -- c-addr' u' ) ( r: u' -- )
	;

\ https://forth-standard.org/standard/core/HOLD

	: hold ( char -- )
		(tmp#^) @		\ get offset
		(tmp#^) + c! 	\ store char at offset
		(tmp#^) @ 1-	\ decrement offset
		(tmp#^) !		\ store offset
	;

\ https://forth-standard.org/standard/core/SIGN

	: sign ( n -- ) 0< if '-' hold then ;

\ https://forth-standard.org/standard/core/num-start

	: (#max) #63 ; \ 64 bytes available, 0..63

	: (#len) ( -- n ) (#max) (tmp#^) @ - ;

	: (#pad) ( n ud -- ud' )
		base @ #16 = if '$' hold else base @ #2 = if '%' hold then then
		swap (#len) - dup 0> if 0 do bl hold loop else drop then
	;

	: (#chr) ( n -- char ) dup #9 > #39 and + '0' + ; \ exploit that 'A' - '9' = 8, 'a' - '9' = 40

	: <# ( -- ) (#max) (tmp#^) ! ;

\ https://forth-standard.org/standard/core/num

	: # ( ud -- ud' )
		base @ u/mod 	( ud -- ud2 u.rem )
		swap
		(#chr) hold		( ud2 u.rem -- ud2 )
	;

\ https://forth-standard.org/standard/core/numS

	: #s ( ud -- ud' ) begin # dup 0= until ;

\ https://forth-standard.org/standard/core/num-end

	: #> ( xd -- c-addr u )
		drop					( xd -- )
		(tmp#^) (tmp#^) @ + 1+	( -- c-addr )
		(#len)					( c-addr -- c-addr u )
	;

\ https://forth-standard.org/standard/core/UDotR

	: (u.r) swap #s (#pad) ;

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

	: u.r2 ( u1 u2 n -- )
		<#
			swap #s  		( u n -- n ud )
			drop ':' hold
			(u.r)
		#> type space
	;

\ https://forth-standard.org/standard/core/Ud

	: u. ( u -- ) 0 u.r ;

\ https://forth-standard.org/standard/core/DotR

	: .r ( n u -- )
		<#
			swap dup abs #s		( n u -- u n du )
			swap sign (#pad)	( u n ud -- u ud )
		#> type space
	;

\ https://forth-standard.org/standard/core/d

	: . ( n -- ) 0 .r ;

\ https://forth-standard.org/standard/core/Sq

	: string, ( c-addr u -- ) swap lit, lit, ;

	: (s") ( "input<quote>" -- c-addr u ) '"' parse state @ if string, then ;

	: s" ( "input<quote>" -- c-addr u ) (s") ; immediate

\ https://forth-standard.org/standard/core/Dotq

	: ." ( "input<quote>" -- ) (s") state @ if postpone type else type then ; immediate

\ https://forth-standard.org/standard/core/Dotp

	: .( ( "ccc<paren>" -- )
		')' parse	\ equiv: [char] )
		type
	; immediate
