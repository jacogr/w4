
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

	: name>prev @ ;
	: name>next $1 cells + @ ;
	: name>list $2 cells + @ ;
	: name>flags >flags @ ;
	: name>xt $4 cells + @ ;

	: list>head @ ;
	: list>tail $1 cells + @ ;
	: list>owner $2 cells + @ ;
	: list>flags >flags @ ;
	: list>file $4 cells + @ ;
	: list>rowcol $2 cells + @ ;

	: (latest>tail) $0120 @ >value @ list>tail ;
	: (latest>value) (latest>tail) name>prev name>xt >value ;

	: (here!) dup $a0000 - $80000000 and 0= #-23 and throw $0100 ! ;
	: allot $0100 @ + (here!) ;
	: aligned $3 + $-4 and ;
	: align $0100 @ aligned (here!) ;
	: (new-xt) $0100 @ $5 cells allot swap over >flags ! swap over >value ! ;
	: reveal $0120 @ >flags dup @ $1 or swap ! ;
	: immediate $0120 @ >flags dup @ $2 or swap ! ;

	: lit $c0de0140 (new-xt) ;
	: lit, lit compile, ;
	: create <builds -1 lit, $0100 @ (latest>value) ! reveal ;
	: variable create $1 cells allot ;
	: constant create (latest>value) ! ;
	: (mmio:) constant ;
	: (mmio@) constant does> @ ;

	$0100 (mmio@) here
	$0104 (mmio:) (here-min)
	$0104 (mmio:) (here-max)
	$0110 (mmio:) source-id
	$0114 (mmio@) >in
	$0118 (mmio@) (lniov^)
	$0120 (mmio@) latest
	$0124 (mmio@) (exec^)
	$0128 (mmio@) (dict^)
	$012c (mmio@) (incl^)
	$0140 (mmio@) (sp^)
	$0144 (mmio@) (rp^)
	$0148 (mmio@) (cp^)
	$0150 (mmio:) state
	$0154 (mmio:) base

	: source (lniov^) >string ;

	: \ source >in ! drop ; immediate

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

\ Helper for allot & aligned that checks and writes to the
\ underlying here pointer location to adavance here
\
\ 	: (here!)	( a-addr -- )
\		dup $a0000 - 		\ subtract from maxiumum memory position
\		$80000000 and 0=	\ signed bit should not be set
\		#-23 and throw 		\ if negative, throw error
\		$0100 !				\ update address, underlying here pointer
\	;

\ https://forth-standard.org/standard/core/ALLOT
\
\ NOTE: As earlier, here is not yet available, $0100 is the pointer
\ that would later (once we have constants) be known as here
\
\ 	: allot ( n -- )
\		$0100 @ + 			\ advance address ny n units
\		(here!)				\ write updated location
\	;

\ https://forth-standard.org/standard/core/ALIGNED
\
\ a-addr is the first aligned address greater than or equal to addr.
\ We have 4-byte cells, so mask the lower bits and advance
\
\	: aligned ( a-addr -- a-addr' ) $3 + $-4 and ;

\ https://forth-standard.org/standard/core/ALIGN
\
\ If the data-space pointer is not aligned, reserve enough space to align it.
\
\ 	: align ( -- )
\		$0100 @ aligned		\ align current address
\		(here!) 			\ write updated value
\	;

\ https://forth-standard.org/standard/core/CREATE
\ https://forth-standard.org/standard/core/VARIABLE
\ https://forth-standard.org/standard/core/CONSTANT

\ https://forth-standard.org/standard/core/SOURCE-ID
\ https://forth-standard.org/standard/core/STATE
\ https://forth-standard.org/standard/core/BASE

\ https://forth-standard.org/standard/core/IMMEDIATE
\
\ Adjusts the flags of the latest definition to be immediate
\ by setting the correct flag, toggling the $02 bit
\
\ see ext/debug.f for all the known flags
\
\		: immediate ( -- )
\			$0120 @ >flags 	\ get flags pointer
\			dup @ $2 or 	\ toggle $02 via or
\			swap ! 			\ write updated flags
\		;

\ https://forth-standard.org/standard/core/SOURCE
\
\		: source ( -- c-addr u )
\			(lniov^) {xt-get-str}	( -- c-addr )
\			(lniov^) {xt-get-len}	( c-addr -- c-addr u )
\		;

\ https://forth-standard.org/standard/core/toIN
\
\		: >in ( -- a-addr ) {lnoff^} ;

\ https://forth-standard.org/standard/core/bs
\
\		: \ ( -- )
\			source	( -- c-addr u )					\ Value of the line buffer & count
\			>in		( c-addr u - c-addr u c-addr )	\ Address of line offset
\			! 		( c-addr u c-addr -- c-addr )	\ Set offset to line length
\			drop 	( c-addr -- )					\ Drop the stored address value
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
