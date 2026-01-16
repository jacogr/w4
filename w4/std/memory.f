require stack.f

\ https://forth-standard.org/standard/core/UNUSED
\
\ u is the amount of space remaining in the region addressed by HERE,
\ in address units.

	: unused ( -- u ) (here-max) here - ;

\ https://forth-standard.org/standard/core/ALIGNED
\
\ a-addr is the first aligned address greater than or equal to addr.
\ We have 4-byte cells, so mask the lower bits and advance

	: aligned ( a-addr -- a-addr' ) $3 + $-4 and ;

\ https://forth-standard.org/standard/core/ALIGN
\
\ If the data-space pointer is not aligned, reserve enough space to align it.

	: align ( -- )
		here aligned		\ align current address
		(here!) 			\ write updated value
	;

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
\
\ Store char at c-addr. When character size is smaller than cell size, only
\ the number of low-order bits corresponding to character size are transferred.

	: c! ( c addr -- )
		dup @           ( c addr -- c addr u )   \ fetch memory
		$ff invert and  ( c addr u -- c addr u ) \ zero out low byte
		rot $ff and     \ zero out high byte of value being stored
		or swap !       \ overwrite low byte of existing contents
	;

\ https://forth-standard.org/standard/core/CComma
\
\ Reserve space for one character in the data space and store char in the
\ space. If the data-space pointer is character aligned when C, begins
\ execution, it will remain character aligned when C, finishes execution.

	: c, ( c -- )
		here c!
		1 allot
	;

\ https://forth-standard.org/standard/core/Comma
\
\ Reserve one cell of data space and store x in the cell. If the data-space
\ pointer is aligned when , begins execution, it will remain aligned when , finishes execution.

	: , ( x -- )
		here !
		1 cells allot
	;

\ https://forth-standard.org/standard/core/TwoFetch
\
\ Fetch the cell pair x1 x2 stored at a-addr. x2 is stored at a-addr and x1 at
\ the next consecutive cell. It is equivalent to the sequence DUP CELL+ @ SWAP @.

	: 2@ ( a-addr -- x1 x2 ) dup cell+ @ swap @ ;

\ https://forth-standard.org/standard/core/TwoStore
\
\ Store the cell pair x1 x2 at a-addr, with x2 at a-addr and x1 at the next
\ consecutive cell. It is equivalent to the sequence SWAP OVER ! CELL+ !.

	: 2! ( x1 x2 a-addr -- ) swap over ! cell+ ! ;

\ mid-point require since the remainder rely on looping being available

require loops.f

\ https://forth-standard.org/standard/string/CMOVE
\
\ If u is greater than zero, copy u consecutive characters from the data
\ space starting at c-addr1 to that starting at c-addr2, proceeding
\ character-by-character from lower addresses to higher addresses.

	: cmove ( src dst u -- )
		begin
			dup	0<>				( src dst u -- src dst u flag )
		while
			>r 					( src dst u -- src dst ) ( r: -- u )
			over c@ 			( src dst -- src dst ch )
			over c! 			( src dst ch -- src dst )
			1+ swap 1+ swap 	( src dst -- src' dst' )
			r> 1- 				( src' dst' -- src' dst' u' ) ( r: u -- )
		repeat
		drop 2drop
	;

\ https://forth-standard.org/standard/string/CMOVEtop
\
\ If u is greater than zero, copy u consecutive characters from the data
\ space starting at c-addr1 to that starting at c-addr2, proceeding
\ character-by-character from higher addresses to lower addresses.

	: cmove> ( src dst u -- )
		begin
			dup 0<> 			( src dst u -- src dst u flag )
		while
			1- >r 				( src dst u -- src dst ) ( r: -- u )
			over r@ + c@ 		( src dst -- src dst ch )
			over r@ + c! 		( src dst ch -- src dst )
			r> 					( src dst -- src dst u ) ( r: u -- )
		repeat
		drop 2drop
	;

\ https://forth-standard.org/standard/core/MOVE
\
\ If u is greater than zero, copy the contents of u consecutive address units
\ at src to the u consecutive address units at dst.

	: move ( src dst u -- )
		dup 0= if 			( src dst u -- src dst u )
			drop 2drop 		( src dst u -- )
			exit
		then
		sp-1@ 				( src dst u -- src dst u dst )
		sp-3@ 				( src dst u dst -- src dst u dst src )
		u< if               ( src dst u dst src -- src dst u )  \ dst < src ?
			cmove 			( src dst u -- )
		else
			cmove> 			( src dst u -- )
		then
	;

\ https://forth-standard.org/standard/core/FILL
\
\ If u is greater than zero, store char in each of u consecutive characters of
\ memory beginning at c-addr.

	: fill ( c-addr u ch -- )
		-rot						( c-addr u ch -- ch c-addr u )
		begin
			dup 0<> 				( ch c-addr u -- ch c-addr u flag )
		while
			sp-2@ sp-2@ c! 			( ch c-addr u -- c-addr u )
			1- swap 1+ swap 		( ch c-addr u -- ch c-addr' u' )
		repeat
		drop 2drop					( ch c-addr u -- )
	;
