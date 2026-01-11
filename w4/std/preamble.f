
	: cells $2 lshift ;
	: depth $0140 @ @ ;
	: sp@ depth cells $0140 @ + ;
	: dup sp@ @ ;
	: drop depth dup 0= #-4 and throw $1 - $0140 @ ! ;
	: over sp@ $1 cells - @ ;
	: swap over over sp@ $3 cells - ! sp@ $1 cells - ! ;
	: or over over xor sp@ $2 cells - @ sp@ $2 cells - @ and  + sp@ $2 cells - ! drop ;

	: >string dup @ swap $1 cells + @ ;
	: >hash $2 cells + ;
	: >flags $3 cells + ;
	: >body $4 cells + ;

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

	: (latest>tail) $0120 @ >body @ list>tail ;
	: (latest>body) (latest>tail) name>prev	name>xt >body ;

	: allot $3 + $-4 and $0100 @ + dup $a0000 - $80000000 and 0= #-23 and throw $0100 ! ;
	: (new-xt) $0100 @ $5 cells allot swap over >flags ! swap over >body ! ;
	: reveal $0120 @ >flags dup @ $1 or swap ! ;
	: immediate $0120 @ >flags dup @ $2 or swap ! ;

	: lit $c0de0140 (new-xt) ;
	: lit, lit compile, ;
	: create <builds -1 lit, $0100 @ (latest>body) ! reveal ;
	: variable create $1 cells allot ;
	: constant create (latest>body) ! ;
	: (mmio:) constant ;
	: (mmio@) constant does> @ ;

	$0100 (mmio:) here
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
	$0160 (mmio:) (tmp^)
	$0170 (mmio:) (tmp#^)

	: source (lniov^) >string ;

	: \ source >in ! drop ; immediate

\ The lines above implements the ability to handle line
\ comments. Start using it immediately by documenting what
\ has been defined above.

\ https://forth-standard.org/standard/core/OR

\ https://forth-standard.org/standard/core/CELLS
\
\		: cells ( n -- n * 4 )
\			#4 * 	\ cells are 32-bit, 4 bytes each
\		;

\ https://forth-standard.org/standard/core/ALLOT
\
\		: allot ( n -- )
\			$0f + $4 rshift $4 lshift 	\ ((n + 15) >> 4) << 4
\			here @ +			( n -- a-addr )
\			here !				( a-addr -- )
\		;

\ https://forth-standard.org/standard/core/ALLOT
\ https://forth-standard.org/standard/core/IMMEDIATE
\ https://forth-standard.org/standard/core/CREATE
\ https://forth-standard.org/standard/core/DUP
\ https://forth-standard.org/standard/core/DROP
\ https://forth-standard.org/standard/core/SWAP
\ https://forth-standard.org/standard/core/VARIABLE
\ https://forth-standard.org/standard/core/CONSTANT

\ https://forth-standard.org/standard/core/SOURCE-ID
\ https://forth-standard.org/standard/core/STATE
\ https://forth-standard.org/standard/core/BASE

\ https://forth-standard.org/standard/core/IMMEDIATE
\
\		: immediate ( -- )
\			$c0de0041       ( -- $41 )  \ immediate ($01) + tokens ($40)
\			latest			\ last compiled token
\			{xt-set-flg}	\ write flag as set
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


\ : (new-xt) ( body flags -- ptr )
\ 	$0100 @ $5 cells allot 	( body flags -- body flags ptr )
\ 	swap over 				( body flags ptr --- body ptr flags ptr )
\ 	>flags !				( body ptr flags ptr -- body ptr )
\ 	swap over				( body ptr -- ptr body ptr )
\ 	>body !					( ptr body ptr -- ptr )
\ ;

\ : lit ( n -- ptr )
\ 	$c0de0140	( n -- n flags )
\ 	(new-xt) 	( n flags -- ptr )
\ ;

\ https://forth-standard.org/standard/core/p
\
\ TODO it should use refill internally for multi-line (as per std)

	: ( \ ( -- )
		')' parse			\ ( -- c-addr u )
		0= #-14 and throw	\ ( c-addr u -- c-addr )
		drop 				\ ( c-addr -- )
	; immediate

( here we now have these comments, although they are not multi-line )
