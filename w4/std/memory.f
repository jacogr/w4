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

	: 2@ ( a-addr -- x1 x2 )
		dup @
		swap cell+ @
	;

\ https://forth-standard.org/standard/core/TwoStore
\
\ Store the cell pair x1 x2 at a-addr, with x2 at a-addr and x1 at the next
\ consecutive cell. It is equivalent to the sequence SWAP OVER ! CELL+ !.

	: 2! ( x1 x2 a-addr -- )
		swap over !
		cell+ !
	;

\ mid-point require since the remainder rely on looping being available

require loops.f

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
