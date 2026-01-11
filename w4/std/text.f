require compile.f
require math.f
require stack.f

\ https://forth-standard.org/standard/core/CFetch
\
\ Fetch the character stored at c-addr. Since the cell size
\ is greater than character size, the high-order bits are zero.
\
\ NOTE (also applies to c!) Since a full cell is fetch/store-ed
\ here, the engine may have alignment issues since it won't be
\ on a boundary. With this in mind, it certainly is probably less
\ efficient than exposing it as a native

	: c@ ( addr -- char ) @ $ff and	;

\ https://forth-standard.org/standard/core/CStore

	: c! ( c addr -- )
		dup @           ( c addr -- c addr u )   \ fetch memory
		$ff invert and  ( c addr u -- c addr u ) \ zero out low byte
		rot $ff and     \ zero out high byte of value being stored
		or swap !       \ overwrite low byte of existing contents
	;

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

	: chars ( n -- n ) ; \ noop, char = 1 byte in size

\ https://forth-standard.org/standard/core/CHARPlus

	: char+ ( a-addr -- a-addr' ) 1+ ;

\ https://forth-standard.org/standard/core/SPACE

	: space ( -- ) bl emit ;

\ https://forth-standard.org/standard/core/SPACES

	: spaces ?dup if 0 do space loop then ;

\ https://forth-standard.org/standard/core/CR

	: cr ( -- ) #10 emit ;

\ https://forth-standard.org/standard/core/CHAR

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

\ https://forth-standard.org/standard/string/CMOVE
\
\ If u is greater than zero, copy u consecutive characters from the data
\ space starting at c-addr1 to that starting at c-addr2, proceeding
\ character-by-character from lower addresses to higher addresses.

	: cmove ( src dst u -- )
		begin
			dup
		while
			>r                 \ save u
			over c@            \ fetch char from src
			>r                 \ save char
			over r> swap c!    \ store char to dst
			1+ swap 1+ swap    \ src++ dst++
			r> 1-              \ restore u--
		repeat
		drop 2drop
	;

\ https://forth-standard.org/standard/string/CMOVEtop
\
\ If u is greater than zero, copy u consecutive characters from the data
\ space starting at c-addr1 to that starting at c-addr2, proceeding
\ character-by-character from higher addresses to lower addresses.

	: cmove> ( src dst u -- )
		dup 0= if 2drop drop exit then
		begin
			dup
		while
			1-
			over over + c@
			rot over + c!
			rot
		repeat
		drop 2drop
	;

\ https://forth-standard.org/standard/core/MOVE
\
\ If u is greater than zero, copy the contents of u consecutive address units
\ at src to the u consecutive address units at dst.

	: move ( src dst u -- )
		2dup swap u< if
			cmove
		else
			cmove>
		then
	;

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
