
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

\ Internal constant helpers for the memory pointers

	: (mmio:) constant ;
	: (mmio@) constant does> @ ;

\ constants as exposed from the wasm environment
\
\ https://forth-standard.org/standard/core/SOURCE-ID
\ https://forth-standard.org/standard/core/STATE
\ https://forth-standard.org/standard/core/BASE

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
