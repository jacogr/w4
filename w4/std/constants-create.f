m4_require_w4(`std/constants-structs.f')

\ https://forth-standard.org/standard/core/ALLOT
\
\ NOTE: As mentioned a number of times below, here is not yet available,
\ $0100 is the pointer to pointer that would later (once we have constants)
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
\ $c0de0140 defined below as literal

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

	: (reveal) ( xt -- )
		>flags		( -- flags-addr )
		dup @		( flags-addr -- flags-addr flags )
		$1 or		( flags-addr flags -- flags-addr flags' )
		swap !		( flags-addr flags' -- )
	;

	: REVEAL ( -- ) latest (reveal) ;

\ Reverse of REVEAL, hides a dictionary entry

	: (hide) ( xt -- )
		>flags		( xt -- flags-addr )
		dup @		( flags-addr -- flags-addr flags )
		$-2 and		( flags-addr flags -- flags-addr flags' )
		swap !		( flags-addr flags' -- )
	;

	: HIDE ( -- ) latest (hide) ;

\ https://forth-standard.org/standard/core/PARSE-NAME
\
\ Skip leading space delimiters. Parse name delimited by a space.
\
\ c-addr is the address of the selected string within the input buffer and
\ u is its length in characters. If the parse area is empty or contains only
\ white space, the resulting string has length zero.

	: PARSE-NAME ( -- c-addr u ) #32 parse-token ;

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

	: (create) ( c-addr u -- )
		build,
		-1 lit,                 \ store body address (does>)
		here (latest>body^) !
		reveal
	;

	: CREATE
		parse-name

		\ -16 attempt to use zero-length string as a name
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

\ https://forth-standard.org/standard/core/BUFFERColon
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name, with the execution semantics defined below. Reserve u
\ address units at an aligned address. Contiguity of this region with any
\ other region is undefined.
\
\ At runtime: a-addr is the address of the space reserved by BUFFER: when it
\ defined name. The program is responsible for initializing the contents.
\
\ NOTE: create uses build, internally, so contents are aligned

	: BUFFER: ( u "<name>" -- addr ) create allot ;

\ https://forth-standard.org/standard/core/CELLPlus
\
\ Add the size in address units of a cell to a-addr1, giving a-addr2.

	1 cells constant CELL

	: CELL+ ( a-addr -- a-addr' ) cell + ;
