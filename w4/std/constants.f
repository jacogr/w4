
\ layouts for xt, aligned with wasm

	\ 	str  : name pointer
	\	len  : name length
	\	hash :  hash for name
	\	flags: always at index 3
	\ 	value: flags-specific value
	: (sizeof-xt) ( -- u ) $5 cells ;

	: (xt>str!) ( c-addr xt -- ) ! ;
	: (xt>len!) ( c-addr xt -- ) $1 cells + ! ;

	: (xt>str+len@) ( xt -- c-addr u ) >str+len ;
	: (xt>str+len!) ( c-addr len xt -- )
		swap over	( c-addr len xt -- c-addr xt len xt )
		(xt>len!)	( c-addr xt len xt -- c-addr xt )
		(xt>str!)	( c-addr xt -- )
	;

	: (xt>hash@) ( a-addr -- u ) $2 cells + @ ;
	: (xt>hash!) ( u a-addr -- ) $2 cells + ! ;

	: (xt>flags@) ( a-addr -- u ) >flags @ ; \ $3 cells
	: (xt>flags!) ( u a-addr -- ) >flags ! ;

	: (xt>value@) ( a-addr -- u ) >value @ ; \ $4 cells
	: (xt>value!) ( u a-addr -- ) >value ! ;

\ layouts for names, aligned with wasm

	\	prev : prev in list
	\	next : next in list
	\ 	link : link (for lookups)
	\	flags: always at index 3
	\	value: xt (or specific to list type)
	: (sizeof-nt) ( -- u ) $5 cells ;

	: (nt>prev@) ( a-addr -- u ) @ ;
	: (nt>prev!) ( u a-addr -- ) ! ;

	: (nt>next@) ( a-addr -- u ) $1 cells + @ ;
	: (nt>next!) ( u a-addr -- ) $1 cells + ! ;

	: (nt>link@) ( a-addr -- u ) $2 cells + @ ;
	: (nt>link!) ( u a-addr -- ) $2 cells + ! ;

	: (nt>flags@) ( a-addr -- u ) >flags @ ;
	: (nt>flags!) ( u a-addr -- ) >flags ! ;

	: (nt>value@) ( a-addr -- u ) >value @ ;
	: (nt>value!) ( u a-addr -- ) >value ! ;

\ layouts for lists, aligned with wasm

	\ 	head  : head pointer
	\ 	tail  : tail pointer
	\ 	owner : parent
	\ 	flags : always at index 3
	\ 	file  : if present
	\ 	rowcol: if present
	: (sizeof-lst) ( -- u ) $6 cells ;

	: (lst>head@) ( a-addr -- u ) @ ;
	: (lst>head!) ( u a-addr -- ) ! ;

	: (lst>tail@) ( a-addr -- u ) $1 cells + @ ;
	: (lst>tail!) ( u a-addr -- ) $1 cells + ! ;

	: (lst>owner@) ( a-addr -- u ) $2 cells + @ ;
	: (lst>owner!) ( u a-addr -- ) $2 cells + ! ;

	: (lst>flags@) ( a-addr -- u ) >flags @ ;
	: (lst>flags!) ( u a-addr -- ) >flags ! ;

	: (lst>file@) ( a-addr -- u ) $4 cells + @ ;
	: (lst>file!) ( u a-addr -- ) $4 cells + ! ;

	: (lst>rowcol@) ( a-addr -- u ) $5 cells + @ ;
	: (lst>rowcol!) ( u a-addr -- ) $5 cells + ! ;

\ layouts for lookup indexes

	\ 	buckets: array of bucket pointers, 2^n
	\ 	mask   : 2^n - 1, mask for bucket lookup
	: (sizeof-idx) ( -- u ) $2 cells ;

	: (idx>buckets@) ( a-addr -- u ) @ ;
	: (idx>buckets!) ( u a-addr -- ) ! ;

	: (idx>mask@) ( a-addr -- u ) $1 cells + @ ;
	: (idx>mask!) ( u a-addr -- ) $1 cells + ! ;

\ https://forth-standard.org/standard/core/HERE
\
\ a-addr is the data-space pointer.

	: (here^) ( -- a-addr ) $0100 ;
	: (here-min) ( -- u ) $0104 @ ;
	: (here-max) ( -- u ) $0108 @ ;

	: HERE ( -- a-addr ) (here^) @ ;

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

	: ALLOT ( n -- )
		here + 			\ advance address ny n units
		(here!)			\ write updated location
	;

\ https://forth-standard.org/standard/core/ALIGNED
\
\ a-addr is the first aligned address greater than or equal to addr.
\ We have 4-byte cells, so mask the lower bits and advance

	: ALIGNED ( a-addr -- a-addr' ) $3 + $-4 and ;

\ https://forth-standard.org/standard/core/ALIGN
\
\ If the data-space pointer is not aligned, reserve enough space to align it.

	: ALIGN ( -- )
		here aligned		\ align current address
		(here!) 			\ write updated value
	;

\ Non-standard but widely known words to create literals and compile it
\ into the body of the latest definition
\
\ `$c0de0140` defined below as literal

	: (new-xt) ( n flags -- a-addr )
		align here				( n flags -- n flags a-addr )
		(sizeof-xt) allot		\ allocate
		swap over (xt>flags!) 	( n flags a-addr -- n a-addr )
		swap over (xt>value!) 	( n a-addr -- a-addr )
	;

	: LIT ( n -- ) $c0de0140 (new-xt) ; \ aligned with (flg-xt-lit) below
	: LIT, ( n -- ) lit compile, ;

\ Swap a dictionary entry from "hidden" to "available to lookups" by
\ flipping the visible flag on the token

	: REVEAL ( -- )
		latest >flags	( -- flags-addr )
		dup @			( flags-addr -- flags-addr flags )
		$1 or			( flags-addr flags -- flags-addr flags' )
		swap !			( flags-addr flags' -- )
	;

\ Reverse of REVEAL, hides a dictionary entry

	: HIDE ( -- )
		latest >flags	( -- flags-addr )
		dup @			( flags-addr -- flags-addr flags )
		$fffffffe and	( flags-addr flags -- flags-addr flags' )
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
	: (latest>head^) (latest>value) (lst>head@) ;
	: (latest>tail^) (latest>value) (lst>tail@) ;
	: (latest>prev^) (latest>tail^) (nt>prev@) ;
	: (latest>body^) (latest>head^) (nt>value@) >value ;

	: (create) ( c-addr u -- )
		build,
		-1 lit,                 \ store body address (does>)
		here (latest>body^) !
		reveal
	;

	: CREATE
		parse-name
		dup 0= #-16 and throw
		(create)
	;

\ https://forth-standard.org/standard/core/toBODY
\
\ a-addr is the data-field address corresponding to xt. An ambiguous condition
\ exists if xt is not for a word defined via CREATE.

	: >BODY ( xt -- a-addr )
		(xt>value@)		\ read address of token list
		(lst>head@)		\ first entry inside the list
		(nt>value@)		\ get the first token, address literal
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

	: VARIABLE create $1 cells allot ;

\ https://forth-standard.org/standard/core/CONSTANT
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below.
\
\ At runtime: Place x on the stack.

	: CONSTANT create (latest>body^) ! ;

\ builtin flags for the environment

	$c0de0000 constant (flg-is-any)
	$c0de0001 constant (flg-is-vis)
	$c0de0002 constant (flg-is-imm)
	$c0de0004 constant (flg-is-var)
	$c0de0010 constant (flg-xt-asm)
	$c0de0020 constant (flg-xt-tkn)
	$c0de0040 constant (flg-xt-lit)
	$c0de0080 constant (flg-xt-does)
	$c0de0100 constant (flg-xt-local)
	$feedca11 constant (flg-list)
	$babeca11 constant (flg-name)

\ environment constants

	$10 constant (env-locals#)
	$2f constant (env-stackmax#)
	$10 constant (env-wordlists-max#)
	#84 constant (env-padsize#)
	$ff constant (env-holdsize#) \ aligns with string-max

\ Internal constant helpers for the exposed/host memory pointers

	: (mmio:) constant ;
	: (mmio@) constant does> @ ;

\ constants as exposed from the wasm environment

\ https://forth-standard.org/standard/core/SOURCE-ID
\ https://forth-standard.org/standard/file/SOURCE-ID
\
\ Identifies the input source as follows: -1 (string), 0 (io), fileid

	$0110 (mmio@) SOURCE-ID

\ https://forth-standard.org/standard/core/SOURCE
\
\ iov that wraps the source, >str+len for source c-addr u

	$0118 (mmio@) (lniov^)

\ latest executing token (latest definition already defined)

	$0124 (mmio@) (exec^)

\ include lookups

	$0128 (mmio@) (incl^)

\ https://forth-standard.org/standard/core/STATE
\
\ a-addr is the address of a cell containing the compilation-state flag.
\ STATE is true when in compilation state, false otherwise. The true value
\ in STATE is non-zero, but is otherwise implementation-defined.
\
\ Only the following standard words alter the value in STATE: : (colon),
\ ; (semicolon), ABORT, QUIT, :NONAME, [ (left-bracket), ] (right-bracket).

	$0130 (mmio:) STATE

\ https://forth-standard.org/standard/core/BASE
\
\ a-addr is the address of a cell containing the current number-conversion
\ radix {{2...36}}.

	$0134 (mmio:) BASE

\ pointers for the return & control stacks (the data stack has already been
\ defined in the preamble)

	$0144 (mmio@) (rs^)
	$0148 (mmio@) (cs^)

\ https://forth-standard.org/standard/search/FORTH-WORDLIST
\
\ Return wid, the identifier of the word list that includes all standard words
\ provided by the implementation. This word list is initially the compilation
\ word list and is part of the initial search order.

	$0150 (mmio@) FORTH-WORDLIST
	$0154 (mmio@) (wid-curr) : (wid-curr!) $0154 ! ;
	$0158 (mmio@) (wid-list)
	$015c (mmio@) (wid-count) : (wid-count!) $015c ! ;

\ pointers for locals definitions

	$0160 (mmio:) (locals-base^)
	$0164 (mmio@) (locals-wid) : (locals-wid!) $0164 ! ;
