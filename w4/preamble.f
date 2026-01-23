
	: CELLS $2 lshift ;

	: (sp^) $0140 @ ;
	: DEPTH (sp^) @ ;
	: SP@ depth cells (sp^) + ;
	: DUP sp@ @ ;
	: DROP depth dup 0= #-4 and throw $1 - (sp^) ! ;
	: OVER sp@ $1 cells - @ ;
	: SWAP over over sp@ $3 cells - ! sp@ $1 cells - ! ;
	: OR over over xor sp@ $2 cells - @ sp@ $2 cells - @ and + sp@ $2 cells - ! drop ;

	: >STR+LEN dup @ swap $1 cells + @ ;
	: >FLAGS $3 cells + ;
	: >VALUE $4 cells + ;

	: LATEST $0120 @ ;
	: IMMEDIATE latest >flags dup @ $02 or swap ! ;

	: >IN $0114 @ ;
	: \ -1 >in ! ; immediate

\ The lines above implements the ability to handle line
\ comments. Start using it immediately by documenting what
\ has been defined above.

\ https://forth-standard.org/standard/core/CELLS
\
\ NOTE: * is only defined at a later point, so the 4 *
\ multiplication is in terms of shifts (possibly even optimal)
\
\		: CELLS ( n -- n * 4 )
\			$2 lshift 	\ cells are 32-bit, 4 bytes each
\		;

\ https://forth-standard.org/standard/core/DEPTH
\
\ Retrieved the count for the stack which is located at
\ $0140 (at this point we don't have constants yet, so the
\ value is hard-coded as an address)
\
\		: DEPTH ( ... -- ... n )
\			(sp^) @	\ first cell on stack is count
\		;

\ sp@ non-standard in forth2012, but widely known
\
\ We define this quite early since it makes the base stack words
\ eay to define (without resorting to yet more "magic constants")
\
\		: SP@ ( -- addr )
\			depth cells \ depth in terms of cells
\			(sp^) + 	\ add to stack pointer for offet addr
\		;

\ https://forth-standard.org/standard/core/DUP
\
\ Duplicates the top stack value via sp@
\
\		: DUP ( n -- n n ) sp@ @ ;

\ https://forth-standard.org/standard/core/DROP
\
\ Drops the top value from the stack by decrementing the
\ stack pointer (count - 1) and storing it
\
\	: DROP ( n -- )
\		depth dup 0= #-4 and throw	\ assert non-0 count
\		$1 - (sp^) ! 				\ write count -1
\	;

\ https://forth-standard.org/standard/core/OVER
\
\ Duplicates the second-from-tos item to the top
\
\	: OVER ( x y -- x y x )
\		sp@ $1 cells - @ 	\ calculate offset and read
\	;

\ https://forth-standard.org/standard/core/SWAP
\
\ Swap the two topmost items on the stack
\
\	: SWAP ( x y -- y x )
\		over over 			( x y -- x y x y )
\		sp@ $3 cells - !	( x y x y -- y y x )
\		sp@ $1 cells - ! 	( y y x -- y x )
\	;

\ https://forth-standard.org/standard/core/OR
\
\ Implements bitwise or in terms of xor & and so
\ that or(a, b) = a^b + a&b
\
\ 	: OR ( a b -- a|b )
\		over over 			( a b -- a b a b )
\		xor 				( a b a b -- a b a^b )
\		sp@ $2 cells - @	( a b a^b -- a b a^b a )
\		sp@ $2 cells - @	( a b a^b a -- a b a^b a b )
\		and +				( a b a^b a b -- a b a|b )
\		sp@ $2 cells - !	( a b a|b -- a|b b )
\		drop				( a|b b -- a|b )
\	;

\ https://forth-standard.org/standard/core/IMMEDIATE
\
\ Adjusts the flags of the latest definition to be immediate
\ by setting the correct flag, toggling the $02 bit
\
\ see constants.f for all the known flags
\
\		: IMMEDIATE ( -- )
\			latest >flags 	\ get flags pointer
\			dup @ $02 or 	\ toggle $02 via or
\			swap ! 			\ write updated flags
\		;

\ https://forth-standard.org/standard/core/toIN
\
\ a-addr is the address of a cell containing the offset in characters from
\ the start of the input buffer to the start of the parse area.
\
\		: >IN $0114 @ ;

\ https://forth-standard.org/standard/core/bs
\
\ Parse and discard the remainder of the parse area. \ is an immediate word.
\
\		: \ ( -- )
\			-1 >in !	\ write max length to (here!)
\		; immediate

\ https://forth-standard.org/standard/core/p
\
\ Parse ccc delimited by ) (right parenthesis). ( is an immediate word.
\
\ The number of characters in ccc may be zero to the number of characters in
\ the parse area.
\
\ NOTE: For the multi-line version, it is defined later inside parse when
\ we have more functions available to us, including loops and proper stack
\ operations.

	: ( \ ( -- )
		')' parse-token		\ ( -- c-addr u )
		0= #-14 and throw	\ ( c-addr u -- c-addr )
		drop 				\ ( c-addr -- )
	; immediate

( here we now have these comments, although they are not multi-line )
