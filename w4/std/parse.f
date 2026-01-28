m4_require_w4(`std/compile.f')
m4_require_w4(`std/constants.f')
m4_require_w4(`std/loops.f')
m4_require_w4(`std/memory.f')
m4_require_w4(`std/search.string.f')
m4_require_w4(`std/stack.f')
m4_require_w4(`std/string.f')

m4_require_w4(`ext/hash.f')
m4_require_w4(`ext/list.f')

\ https://forth-standard.org/standard/core/SOURCE
\
\ c-addr is the address of, and u is the number of characters in
\ the input buffer.

	: SOURCE (lniov^) >str+len ;

\ https://forth-standard.org/standard/file/INCLUDED
\
\ Remove c-addr u from the stack. Save the current input source specification,
\ including the current value of SOURCE-ID. Open the file specified by c-addr u,
\ store the resulting fileid in SOURCE-ID, and make it the input source. Store
\ zero in BLK. Other stack effects are due to the words included.
\
\ Repeat until end of file: read a line from the file, fill the input buffer
\ from the contents of that line, set >IN to zero, and interpret.
\
\ Text interpretation begins at the start of the file.
\
\ When the end of the file is reached, close the file and restore the input source
\ specification to its saved value.
\
\ An ambiguous condition exists if the named file can not be opened, if an I/O
\ exception occurs reading the file, or if an I/O exception occurs while closing
\ the file. When an ambiguous condition exists, the status (open or closed) of any
\ files that were being interpreted is implementation-defined.
\
\ INCLUDED may allocate memory in data space before it starts interpreting the file.

	(new-lookup-small) constant (included-wid)

	: (if-not-included-add) ( c-addr u -- c-addr u f )
		(included-wid) sp-2@ sp-2@		( c-addr u -- c-addr u wid c-addr u )
		2dup host::hash					( c-addr u wid c-addr u -- c-addr u wid c-addr u hash )
		(lookup-find)					( c-addr u wid c-addr u hash -- c-addr u a-addr )

		\ append if not found
		0= if
			(included-wid)				( c-addr u -- c-addr u wid )
			(lookup-string-append)		( c-addr u wid -- a-addr )
			drop true					( a-addr -- c-addr u f )
		else 2drop false then			( c-addr u -- f )
	;

	: INCLUDED ( i * x c-addr u -- j * x )
		2dup (if-not-included-add)		( c-addr u -- c-addr u f )
		drop included					( c-addr u f -- )
	;

\ https://forth-standard.org/standard/file/INCLUDE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of INCLUDED.

	: INCLUDE ( i * x "name" -- j * x ) parse-name included	;

\ https://forth-standard.org/standard/file/REQUIRED
\
\ If the file specified by c-addr u has been INCLUDED or REQUIRED already,
\ but not between the definition and execution of a marker (or equivalent
\ usage of FORGET), discard c-addr u; otherwise, perform the function of
\ INCLUDED.
\
\ An ambiguous condition exists if a file is REQUIRED while it is being
\ REQUIRED or INCLUDED.
\
\ An ambiguous condition exists, if a marker is defined outside and executed
\ inside a file or vice versa, and the file is REQUIRED again.
\
\ An ambiguous condition exists if the same file is REQUIRED twice using different
\ names (e.g., through symbolic links), or different files with the same name are
\ REQUIRED (by doing some renaming between the invocations of REQUIRED).
\
\ An ambiguous condition exists if the stack effect of including the file is not
\ ( i * x -- i * x ).

	: REQUIRED ( i * x c-addr u -- i * x )
		2dup (if-not-included-add) if	( c-addr u -- c-addr u )
			included					( c-addr u -- )
		else 2drop then					( c-addr u -- )
	;

\ https://forth-standard.org/standard/file/REQUIRE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of REQUIRED.

 	: REQUIRE ( i * x "name" -- j * x ) parse-name required ;

\ https://forth-standard.org/standard/core/PARSE
\
\ c-addr is the address (within the input buffer) and u is the length of the
\ parsed string. If the parse area was empty, the resulting string has a zero
\ length.

	: PARSE ( ch -- c-addr u )
		$-1 source				( ch -- ch -1 base len )
		>in @ >r				( r: -- in0 )

		swap r@ +				( ch -1 base len -- ch -1 len start ) \ start = base + in0
		swap r@ -				( ch -1 len start -- ch -1 start rem ) \ rem = len - in0

		over swap				( ch -1 start rem -- ch -1 start cur rem ) \ cur = start

		begin
			sp-3@ over and		( ch -1|0 start cur rem -- ch -1|0 start cur rem f ) \ f = (-1|0 == -1) & (rem != 0)
		while
			over c@				( ch -1 start cur rem -- ch -1 start cur rem ch-at )
			sp-5@ =				( ch -1 start cur rem ch-at -- ch -1 start cur rem f ) \ f = ch-at == ch

			if
				0 sp-4!			( ch -1 start cur rem -- ch 0 start cur rem )
			else
				1- swap			( ch -1 start cur rem -- ch -1 start rem' cur ) \ rem' = rem - 1
				1+ swap 		( ch -1 start cur rem -- ch -1 start cur' rem' ) \ cur' = cur + 1
			then
		repeat

		swap					( ch -1|0 start cur rem -- ch -1|0 start rem cur )
		sp-2@ -					( ch -1|0 start rem curr -- ch -1|0 start rem u ) ( r: in0 ) \ u = cur - start

		over 0<> negate			( ch -1|0 start rem u -- ch -1|0 start rem u 1|0 ) \ found = (rem != 0) ? 1 : 0
		over +					( ch -1|0 start rem u 1|0 -- ch -1|0 start rem u u' ) \ u' = 1|0 + u
		r@ +					( ch -1|0 start rem u u' -- ch -1|0 start cur rem u newin ) ( r: in0 ) \ newin = u' + in0

		>in !					( ch -1|0 start rem u newin -- ch -1|0 start cur rem u )

		swap drop				( ch -1|0 start rem u -- ch -1|0 start u )
		sp-2!					( ch -1|0 start u -- ch u start )
		sp-2!					( ch u start -- start u )

		r> drop					( r: in0 -- )
	;

\ https://forth-standard.org/standard/core/p
\
\ Parse ccc delimited by ) (right parenthesis). ( is an immediate word.
\
\ The number of characters in ccc may be zero to the number of characters in
\ the parse area.
\
\ NOTE: This is the later, multi-line version of our ( ... ) implementation

	\ (parse-multi) ( delim xt -- )
	\ Calls xt as ( c-addr u -- ) for each chunk.
	\ Stops when delim is found. If REFILL fails before delim, throws -14 (yours).
	: (parse-multi) ( ch xt -- )
		begin
			source nip >in @ - >r		( ch xt ) ( r: -- rem )
			sp-1@ parse					( ch xt -- ch xt c-addr u )
			dup r> < 0=	>r				( ch xt c-addr u ) ( r: rem -- more? ) \ more? = (u < rem) == 0
			sp-2@ execute				( ch xt c-addr u -- ch xt )
			r> 							( ch xt -- ch xt more? )
		while
			\ -14 interpreting a compile-only word
			refill 0= #-14 and throw
		repeat
		2drop							( ch xt -- )
	;

	: ( ( -- ) ')' ['] 2drop (parse-multi) ; immediate

(
	At this point in time we should have multi-line comments available
	to us. If things break at this point in the code, then... guess what,
	the above functions are not doing what they are supposed to do.
)

\ https://forth-standard.org/standard/core/WORD
\
\ Skip leading delimiters. Parse characters ccc delimited by char. An
\ ambiguous condition exists if the length of the parsed string is greater
\ than the implementation-defined length of a counted string.
\
\ c-addr is the address of a transient region containing the parsed word as a
\ counted string. If the parse area was empty or contained no characters other
\ than the delimiter, the resulting string has a zero length. A program may
\ replace characters within the string.

	string-max 1+ buffer: (word-tmp-buf) \ 256 + 1 (length byte at 0)

	: (parse-whitespace-skip) ( -- )
		begin
			source nip >in @ <
		while
			source drop >in @ + c@
			#33 u<
		while
			$1 >in +!
		repeat then
	;

	: WORD ( char "<chars>ccc<char>" -- c-addr )
		(parse-whitespace-skip)	\ skip leading whitespace
		parse					( ch -- c-addr u )
		(word-tmp-buf)			( c-addr u -- c-addr u dst )
		(place-result)			( c-addr u dst -- dst )
	;

\ https://forth-standard.org/standard/core/FIND
\
\ Find the definition named in the counted string at c-addr. If the definition
\ is not found, return c-addr and zero. If the definition is found, return its
\ execution token xt. If the definition is immediate, also return one (1),
\ otherwise also return minus-one (-1).
\
\ NOTE/TODO This actually has the same functionality as the FIND in search.f
\ since the wasm find-name adds the locals & wordlists functionality. Need to
\ untangle with a locally defined find-name that has all the functionality

	: FIND ( c-addr -- c-addr 0 | xt 1 | xt -1 )
		dup >r						( c-addr -- c-addr ) ( r: -- c-addr )
		count find-name				( c-addr -- nt | 0 )

		dup 0= if
			drop					( 0 -- )
			r> 0					( -- c-addr 0 )
		else
			r> drop
			(nt>value@)				( nt -- xt )
			dup is-xt-immediate?	( xt -- xt f )
			1 -1 select				\ -1 normal, 1 immediate
		then
	;

\ https://forth-standard.org/standard/core/SAVE-INPUT
\
\ ( -- xn ... x1 n ) x1 through xn describe the current state of the input
\ source specification for later use by RESTORE-INPUT.
\
\ Minimal (evaluate-friendly) save/restore: only snapshots >in, ignores source
\ identity, i.e. cannot restore accross input sources (or lines)

	: SAVE-INPUT ( -- x1 n )
		>in @ source-id $2
	;

\ https://forth-standard.org/standard/core/RESTORE-INPUT
\
\ Attempt to restore the input source specification to the state described by
\ x1 through xn. flag is true if the input source specification cannot be so
\ restored.
\
\ An ambiguous condition exists if the input source represented by the arguments
\ is not the same as the current input source.

	: RESTORE-INPUT ( x1 .. xn n -- flag )
		dup $2 = if
			drop                 \ x1 x2
			source-id <> if      \ source-id changed => cannot restore
				drop true
			else
				>in ! false 	\ restore >in
			then
		else 0 ?do drop loop true then
	;
