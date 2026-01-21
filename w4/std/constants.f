
\ layouts for xt, aligned with wasm

	\ 	str  : name pointer
	\	len  : name length
	\	hash :  hash for name
	\	flags: always at index 3
	\ 	value: flags-specific value
	: (sizeof-xt) $5 cells ;

	: (xt>string@) ( xt -- c-addr u ) >string ;

	: (xt>hash@) $2 cells + @ ;
	: (xt>hash!) $2 cells + ! ;

	: (xt>flags@) >flags @ ;
	: (xt>flags!) >flags ! ;

	: (xt>value@) >value @ ;
	: (xt>value!) >value ! ;

\ layouts for names, aligned with wasm

	\	prev : prev in list
	\	next : next in list
	\ 	link : link (for lookups)
	\	flags: always at index 3
	\	value: xt (or specific to list type)
	: (sizeof-nt) $5 cells ;

	: (name>prev@) @ ;
	: (name>prev!) ( prev -- ) ! ;

	: (name>next@) $1 cells + @ ;
	: (name>next!) ( next -- ) $1 cells + ! ;

	: (name>link@) $2 cells + @ ;
	: (name>link!) ( link -- ) $2 cells + ! ;

	: (name>flags@) >flags @ ;
	: (name>flags!) ( flags -- ) >flags ! ;

	: (name>value@) >value @ ;
	: (name>value!) ( flags -- ) >value ! ;

\ layouts for lists, aligned with wasm

	\ 	head  : head pointer
	\ 	tail  : tail pointer
	\ 	owner : parent
	\ 	flags : always at index 3
	\ 	file  : if present
	\ 	rowcol: if present
	: (sizeof-list) $6 cells ;

	: (list>head@) @ ;
	: (list>head!) ( head -- ) ! ;

	: (list>tail@) $1 cells + @ ;
	: (list>tail!) ( tail -- ) $1 cells + ! ;

	: (list>owner@) $2 cells + @ ;
	: (list>owner!) ( owner -- ) $2 cells + ! ;

	: (list>flags@) >flags @ ;
	: (list>flags!) ( flags -- ) >flags ! ;

	: (list>file@) $4 cells + @ ;
	: (list>file!) ( file -- ) $4 cells + ! ;

	: (list>rowcol@) $5 cells + @ ;
	: (list>rowcol!) ( rowcol -- ) $5 cells + ! ;

\ layouts for lookup indexes

	\ 	buckets: array of bucket pointers, 2^n
	\ 	mask   : 2^n - 1, mask for bucket lookup
	: (sizeof-lookup) $2 cells ;

	: (lookup>buckets@) ( a-addr -- v ) @ ;
	: (lookup>buckets!) ( v a-addr -- ) ! ;

	: (lookup>mask@) ( a-addr -- v ) $1 cells + @ ;
	: (lookup>mask!) ( v a-addr -- ) $1 cells + ! ;


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

\ Non-standard but widely known words to create literals and compile it
\ into the body of the latest definition
\
\ `$c0de0140` defined below as literal

	: (new-xt) ( flags -- )
		align here				( flags -- flags here^ )
		(sizeof-xt) allot		\ allocate
		swap over (xt>flags!) 	\ write flags
		swap over (xt>value!) 	\ write address
	;

	: lit ( n -- ) $c0de0140 (new-xt) ; \ aligned with (flg-xt-lit) below
	: lit, ( n -- ) lit compile, ;

\ Swap a dictionary entry from "hidden" to "available to lookups" by
\ flipping the visible flag on the token

	: reveal ( -- )
		latest >flags	( -- flags-addr )
		dup @			( flags-addr -- flags-addr flags )
		$1 or			( flags-addr flags -- flags-addr flags' )
		swap !			( flags-addr flags' -- )
	;

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
	: (latest>head^) (latest>value) (list>head@) ;
	: (latest>tail^) (latest>value) (list>tail@) ;
	: (latest>prev^) (latest>tail^) (name>prev@) ;
	: (latest>body^) (latest>head^) (name>value@) >value ;

	: create
		parse-name
		dup 0= #-16 and throw
		build,
		-1 lit,					\ store body address (does>)
		here (latest>body^) !
		reveal
	;

\ https://forth-standard.org/standard/core/toBODY
\
\ a-addr is the data-field address corresponding to xt. An ambiguous condition
\ exists if xt is not for a word defined via CREATE.

	: >body ( xt -- a-addr )
		(xt>value@)		\ read address of token list
		(list>head@)	\ first entry inside the list
		(name>value@)	\ get the first token, address literal
		(xt>value@)		\ read the value
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
	$feedca11 constant (flg-list)
	$babeca11 constant (flg-name)

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
