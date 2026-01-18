require stack.f

\ https://forth-standard.org/standard/core/UNUSED
\
\ u is the amount of space remaining in the region addressed by HERE,
\ in address units.

	: unused ( -- u ) (here-max) here - ;

\ https://forth-standard.org/standard/core/Comma
\
\ Reserve one cell of data space and store x in the cell. If the data-space
\ pointer is aligned when , begins execution, it will remain aligned when ,
\ finishes execution.

	: , ( x -- )
		here !
		1 cells allot
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

\ Non-standard extension to c!, as used inside s\" (and part of that proposal,
\ so pretty well-known)

	: c+! ( c c-addr -- ) tuck c@ + swap c! ;

\ https://forth-standard.org/standard/core/CComma
\
\ Reserve space for one character in the data space and store char in the
\ space. If the data-space pointer is character aligned when C, begins
\ execution, it will remain character aligned when C, finishes execution.

	: c, ( c -- )
		here c!
		1 allot
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

\ Helper to store 2 values (no swap here, as per std tests)

	: 2, ( x1 x2 -- ) , , ;

\ https://forth-standard.org/standard/core/BUFFERColon
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name, with the execution semantics defined below. Reserve u
\ address units at an aligned address. Contiguity of this region with any
\ other region is undefined.
\
\ At runtime: a-addr is the address of the space reserved by BUFFER: when it
\ defined name. The program is responsible for initializing the contents.
\
\ NOTE: create uses build, internally, so contents are aligned

	: buffer: ( u "<name>" -- addr ) create allot ;

\ https://forth-standard.org/standard/core/PAD
\
\ c-addr is the address of a transient region that can be used to hold data
\ for intermediate processing.
\
\ The size of the scratch area whose address is returned by PAD shall be
\ at least 84 characters. The contents of the region addressed by PAD are
\ intended to be under the complete control of the user: no words defined in
\ this standard place anything in the region. Non-standard words provided by
\ an implementation may use PAD, but such use shall be documented.

	#84 buffer: pad

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
		2drop drop					( ch c-addr u -- )
	;

\ https://forth-standard.org/standard/core/ERASE
\
\ If u is greater than zero, clear all bits in each of u consecutive address units
\ of memory beginning at addr.

	: erase ( a-addr u -- ) 0 fill ;
