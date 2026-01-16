
\ layouts for xt, aligned with wasm

	: >string ( -- c-addr u ) dup @ swap $1 cells + @ ;
	: >hash ( -- a-addr ) $2 cells + ;
	\ : >flags ( -- a-addr ) $3 cells + ; \ defined in preamble
	: >value ( -- a-addr ) $4 cells + ;
	: (sizeof-xt) $5 cells ;

\ layouts for names, aligned with wasm

	: name>prev @ ;
	: name>next $1 cells + @ ;
	: name>list $2 cells + @ ;
	: name>flags >flags @ ;
	: name>xt >value @ ;

\ layouts for lists, aligned with wasm

	: list>head @ ;
	: list>tail $1 cells + @ ;
	: list>owner $2 cells + @ ;
	: list>flags >flags @ ;
	: list>file $4 cells + @ ;
	: list>rowcol $5 cells + @ ;

\ https://forth-standard.org/standard/core/HERE
\
\ a-addr is the data-space pointer.

	: (here^) ( -- a-addr ) $0100 ;
	: (here-min) ( -- u ) $0104 @ ;
	: (here-max) ( -- u ) $0108 @ ;

	: here ( -- a-addr ) (here^) @ ;

\ Helper for allot & aligned that checks and writes to the
\ underlying here pointer location to adavance here

	: (here!)	( a-addr -- )
		dup (here-max) - 	\ subtract from maxiumum memory position
		$80000000 and 0=	\ signed bit should not be set
		#-23 and throw 		\ if negative, throw error
		(here^) !			\ update address, underlying here pointer
	;

\ https://forth-standard.org/standard/core/ALLOT
\
\ NOTE: As mentioned a number of times below, `here` is not yet available,
\ `$0100` is the pointer to pointer that would later (once we have constants)
\ be known as here

	: allot ( n -- )
		here + 			\ advance address ny n units
		(here!)			\ write updated location
	;

\ Non-standard but widely known words to create literals and compile it
\ into the body of the latest definition
\
\ `$c0de0140` defined below as literal
\
\ FIXME Move this out of constants once we have >body used correctly
\ inside the create definition
\ FIXME We need to ensure we are aligning the contents

	: (new-xt) here (sizeof-xt) allot swap over >flags ! swap over >value ! ;
	: lit $c0de0140 (new-xt) ;
	: lit, lit compile, ;

\ Swap a dictionary entry from "hidden" to "available to lookups" by
\ flipping the visible flag on the token

	: reveal latest >flags dup @ $1 or swap ! ;

\ https://forth-standard.org/standard/core/CREATE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below. If the
\ data-space pointer is not aligned, reserve enough data space to align it.
\ The new data-space pointer defines name's data field. CREATE does not
\ allocate data space in name's data field.
\
\ At runtime for create-ed word: a-addr is the address of name's data field.
\ The execution semantics of name may be extended by using DOES>.
\
\ NOTE <builds is aligned, so the dfa is aligned as per the specification

	: (latest>value) latest >value @ ;
	: (latest>head^) (latest>value) list>head ;
	: (latest>tail^) (latest>value) list>tail ;
	: (latest>prev^) (latest>tail^) name>prev ;
	: (latest>body^) (latest>head^) name>xt >value ;

	: create parse-name build, -1 lit, here (latest>body^) ! reveal ;

\ https://forth-standard.org/standard/core/toBODY
\
\ a-addr is the data-field address corresponding to xt. An ambiguous condition
\ exists if xt is not for a word defined via CREATE.

	: >body ( xt -- a-addr )
		>value @	\ read address of token list
		list>head	\ first entry inside the list
		name>xt		\ get the first token, address literal
		>value @	\ read the value
	;

\ https://forth-standard.org/standard/core/VARIABLE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create
\ a definition for name with the execution semantics defined below. Reserve
\ one cell of data space at an aligned address.
\
\ At runtime: a-addr is the address of the reserved cell. A program is
\ responsible for initializing the contents of the reserved cell.

	: variable create $1 cells allot ;

\ https://forth-standard.org/standard/core/CONSTANT
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below.
\
\ At runtime: Place x on the stack.

	: constant create (latest>body^) ! ;

\ builtin flags for the environment

	$c0de0000 constant (flg-set-any)
	$c0de0001 constant (flg-set-vis)
	$c0de0002 constant (flg-set-imm)
	$c0de0004 constant (flg-set-var)
	$c0de0010 constant (flg-xt-asm)
	$c0de0020 constant (flg-xt-tkn)
	$c0de0040 constant (flg-xt-lit)
	$c0de0080 constant (flg-xt-does)
	$deadfeed constant (flg-list)
	$feedc0de constant (flg-name)

\ Internal constant helpers for the exposed/host memory pointers

	: (mmio:) constant ;
	: (mmio@) constant does> @ ;

\ constants as exposed from the wasm environment

\ https://forth-standard.org/standard/core/SOURCE-ID
\ https://forth-standard.org/standard/file/SOURCE-ID
\
\ Identifies the input source as follows: -1 (string), 0 (io), fileid

	$0110 (mmio@) source-id

\ https://forth-standard.org/standard/core/SOURCE
\
\ iov that wraps the source, >string for source c-addr u

	$0118 (mmio@) (lniov^)

\ latest executing token

	$0124 (mmio@) (exec^)

\ dictionary & include lookups

	$0128 (mmio@) (dict^)
	$012c (mmio@) (incl^)

\ pointers for the return & control stacks

	$0144 (mmio@) (rp^)
	$0148 (mmio@) (cp^)

\ https://forth-standard.org/standard/core/STATE
\
\ a-addr is the address of a cell containing the compilation-state flag.
\ STATE is true when in compilation state, false otherwise. The true value
\ in STATE is non-zero, but is otherwise implementation-defined.
\
\ Only the following standard words alter the value in STATE: : (colon),
\ ; (semicolon), ABORT, QUIT, :NONAME, [ (left-bracket), ] (right-bracket).

	$0150 (mmio:) state

\ https://forth-standard.org/standard/core/BASE
\
\ a-addr is the address of a cell containing the current number-conversion
\ radix {{2...36}}.

	$0154 (mmio:) base
