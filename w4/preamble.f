
	: cells $2 lshift ;
	: depth $0140 @ @ ;
	: sp@ depth cells $0140 @ + ;
	: dup sp@ @ ;
	: drop depth dup 0= #-4 and throw $1 - $0140 @ ! ;
	: over sp@ $1 cells - @ ;
	: swap over over sp@ $3 cells - ! sp@ $1 cells - ! ;
	: or over over xor sp@ $2 cells - @ sp@ $2 cells - @ and + sp@ $2 cells - ! drop ;

	: >string dup @ swap $1 cells + @ ;
	: >hash $2 cells + ;
	: >flags $3 cells + ;
	: >value $4 cells + ;
	: >body $5 cells + @ ;

	: immediate $0120 @ >flags dup @ $2 or swap ! ;

	: \ -1 $0114 @ ! ; immediate

\ The lines above implements the ability to handle line
\ comments. Start using it immediately by documenting what
\ has been defined above.

\ https://forth-standard.org/standard/core/CELLS
\
\ NOTE: * is only defined at a later point, so the 4 *
\ multiplication is in terms of shifts (possibly even optimal)
\
\		: cells ( n -- n * 4 )
\			$2 lshift 	\ cells are 32-bit, 4 bytes each
\		;

\ https://forth-standard.org/standard/core/DEPTH
\
\ Retrieved the count for the stack which is located at
\ $0140 (at this point we don't have constants yet, so the
\ value is hard-coded as an address)
\
\		: depth ( ... -- ... n )
\			$0140 @ @	\ first cell on stack is count
\		;

\ sp@ non-standard in forth2012, but widely known
\
\ We define this quite early since it makes the base stack words
\ eay to define (without resorting to yet more "magic constants")
\
\		: sp@ ( -- addr )
\			depth cells \ depth in terms of cells
\			$0140 @ + 	\ add to stack pointer for offet addr
\		;

\ https://forth-standard.org/standard/core/DUP
\
\ Duplicates the top stack value via sp@
\
\		: dup ( n -- n n ) sp@ @ ;

\ https://forth-standard.org/standard/core/DROP
\
\ Drops the top value from the stack by decrementing the
\ stack pointer (count - 1) and storing it
\
\	: drop ( n -- )
\		depth dup 0= #-4 and throw	\ assert non-0 count
\		$1 - $0140 @ ! 				\ write count -1
\	;

\ https://forth-standard.org/standard/core/OVER
\
\ Duplicates the second-from-tos item to the top
\
\	: over ( x y -- x y x )
\		sp@ $1 cells - @ 	\ calculate offset and read
\	;

\ https://forth-standard.org/standard/core/SWAP
\
\ Swap the two topmost items on the stack
\
\	: swap ( x y -- y x )
\		over over 			( x y -- x y x y )
\		sp@ $3 cells - !	( x y x y -- y y x )
\		sp@ $1 cells - ! 	( y y x -- y x )
\	;

\ https://forth-standard.org/standard/core/OR
\
\ Implements bitwise or in terms of xor & and so
\ that or(a, b) = a^b + a&b
\
\ 	: or ( a b -- a|b )
\		over over 			( a b -- a b a b )
\		xor 				( a b a b -- a b a^b )
\		sp@ $2 cells - @	( a b a^b -- a b a^b a )
\		sp@ $2 cells - @	( a b a^b a -- a b a^b a b )
\		and +				( a b a^b a b -- a b a|b )
\		sp@ $2 cells - !	( a b a|b -- a|b b )
\		drop				( a|b b -- a|b )
\	;

\ https://forth-standard.org/standard/core/toBODY
\
\ a-addr is the data-field address corresponding to xt. An ambiguous condition
\ exists if xt is not for a word defined via CREATE.

\ https://forth-standard.org/standard/core/IMMEDIATE
\
\ Adjusts the flags of the latest definition to be immediate
\ by setting the correct flag, toggling the $02 bit
\
\ see constants.f for all the known flags
\
\		: immediate ( -- )
\			$0120 @ >flags 	\ get flags pointer
\			dup @ $2 or 	\ toggle $02 via or
\			swap ! 			\ write updated flags
\		;

\ https://forth-standard.org/standard/core/bs
\
\ Parse and discard the remainder of the parse area. \ is an immediate word.
\
\		: \ ( -- )
\			-1 $0114 @ !	\ write max length to (here!)
\		; immediate

\ https://forth-standard.org/standard/core/p
\
\ TODO it should use refill internally for multi-line (as per std),
\ this can only happen much later with more base words available to us

	: ( \ ( -- )
		')' parse			\ ( -- c-addr u )
		0= #-14 and throw	\ ( c-addr u -- c-addr )
		drop 				\ ( c-addr -- )
	; immediate

( here we now have these comments, although they are not multi-line )
