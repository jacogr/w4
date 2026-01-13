
\ layouts for names and lists, aligned with the wasm implementation

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

\ Helper for allot & aligned that checks and writes to the
\ underlying here pointer location to adavance here
\
	: (here!)	( a-addr -- )
		dup $a0000 - 		\ subtract from maxiumum memory position
		$80000000 and 0=	\ signed bit should not be set
		#-23 and throw 		\ if negative, throw error
		$0100 !				\ update address, underlying here pointer
	;

\ https://forth-standard.org/standard/core/ALLOT
\
\ NOTE: As mentioned a number of times below, `here` is not yet available,
\ `$0100` is the pointer to pointer that would later (once we have constants)
\ be known as here

	: allot ( n -- )
		$0100 @ + 			\ advance address ny n units
		(here!)				\ write updated location
	;

\ Non-standard but widely known words to create literals and compile it
\ into the body of the latest definition
\
\ `$0100 @` defined below as `latest`
\ `$c0de0140` defined below as literal
\
\ FIXME Move this out of constants once we have >body used correctly
\ inside the create definition

	: (new-xt) $0100 @ $6 cells allot swap over >flags ! swap over >value ! ;
	: lit $c0de0140 (new-xt) ;
	: lit, lit compile, ;

\ Swap a dictionary entry from "hidden" to "available to lookups" by
\ flipping the visible flag on the token
\
\ `$0120` defined below as `latest`

	: reveal $0120 @ >flags dup @ $1 or swap ! ;

\ https://forth-standard.org/standard/core/CREATE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below. If the
\ data-space pointer is not aligned, reserve enough data space to align it.
\ The new data-space pointer defines name's data field. CREATE does not
\ allocate data space in name's data field.
\
\ `$0100 @` defined below as `here`
\ `$0120` defined below as `latest`
\
\ FIXME As per standards desciption, the contents is not (yet) aligned

	: (latest>tail) $0120 @ >value @ list>tail ;
	: (latest>body) (latest>tail) name>prev name>xt >body ;
	: (latest>value) (latest>tail) name>prev name>xt >value ;

	: create <builds -1 lit, $0100 @ (latest>value) ! reveal ;

\ https://forth-standard.org/standard/core/VARIABLE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create
\ a definition for name with the execution semantics defined below. Reserve
\ one cell of data space at an aligned address.
\
\ At runtime: a-addr is the address of the reserved cell. A program is
\ responsible for initializing the contents of the reserved cell.
\
\ FIXME As per standards desciption, the contents is not (yet) aligned

	: variable create $1 cells allot ;

\ https://forth-standard.org/standard/core/CONSTANT
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below.
\
\ At runtime: Place x on the stack.

	: constant create (latest>value) ! ;

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

\ https://forth-standard.org/standard/core/HERE
\
\ addr is the data-space pointer.

	$0100 (mmio@) here
	$0104 (mmio:) (here-min)
	$0104 (mmio:) (here-max)

\ https://forth-standard.org/standard/core/SOURCE-ID

	$0110 (mmio:) source-id

\ https://forth-standard.org/standard/core/toIN
\
\ a-addr is the address of a cell containing the offset in characters from
\ the start of the input buffer to the start of the parse area.

	$0114 (mmio@) >in

\ https://forth-standard.org/standard/core/SOURCE
\
\ iov that wraps the source, >string for source c-addr u

	$0118 (mmio@) (lniov^)

\ latest (last compiled, in compilation) token

	$0120 (mmio@) latest

\ latest executing token

	$0124 (mmio@) (exec^)

\ dictionary & include lookups

	$0128 (mmio@) (dict^)
	$012c (mmio@) (incl^)

\ pointers for the stacks

	$0140 (mmio@) (sp^)
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
