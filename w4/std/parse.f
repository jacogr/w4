require compile.f
require loops.f
require memory.f
require stack.f

\ https://forth-standard.org/standard/core/SOURCE
\
\ c-addr is the address of, and u is the number of characters in
\ the input buffer.

	: source (lniov^) >string ;

\ https://forth-standard.org/standard/file/INCLUDE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of INCLUDED.

	: include ( i * x "name" -- j * x ) parse-name included	;

\ https://forth-standard.org/standard/core/PARSE
\
\ c-addr is the address (within the input buffer) and u is the length of the
\ parsed string. If the parse area was empty, the resulting string has a zero
\ length.

	: parse ( ch -- c-addr u )
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
			refill 0= #-14 and throw
		repeat
		2drop							( ch xt -- )
	;

	: ( ( -- ) ')' ['] 2drop (parse-multi) ; immediate

(
	At this point in time we should have multi-line comments available
	to us. If things break at this point in-time, guess what, the above
	functions are not doing what they are supposed to do.
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

	$ff 1+ buffer: (word-tmp-buf) \ 255 + 1 (length byte at 0)

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

	: word ( char "<chars>ccc<char>" -- c-addr )
		(parse-whitespace-skip)	\ skip leading whitespace
		parse $ff and			( ch -- c-addr u' ) \ limit length to 255 chars
		(word-tmp-buf) >r 		( c-addr u ) ( r: dst )
		dup r@ c! 				( c-addr u -- c-addr u' )	\ store count
		r@ 1+ swap cmove		( c-addr u -- )             \ copy chars
		r>						( -- dst ) ( r: dst -- )
	;

\ https://forth-standard.org/standard/core/COUNT
\
\ Return the character string specification for the counted string
\ stored at c-addr1

	: count ( c-addr1 -- c-addr2 u )
		dup c@ 		\ fetch count
		swap 1+ 	\ point to first char
		swap
	;

\ https://forth-standard.org/standard/core/FIND
\
\ Find the definition named in the counted string at c-addr. If the definition
\ is not found, return c-addr and zero. If the definition is found, return its
\ execution token xt. If the definition is immediate, also return one (1),
\ otherwise also return minus-one (-1).

	: find ( c-addr -- c-addr 0 | xt 1 | xt -1 )
		dup >r
		count find-name              \ nt | 0
		dup 0= if
			drop
			r> 0
		else
			r> drop
			name>xt                    \ xt
			dup not-immediate?		\ -1 if not immediate, 0 if immediate
			-1 1 select                \ -1 normal, 1 immediate
		then
	;

\ https://forth-standard.org/standard/core/SAVE-INPUT
\
\ ( -- xn ... x1 n ) x1 through xn describe the current state of the input
\ source specification for later use by RESTORE-INPUT.
\
\ Minimal (evaluate-friendly) save/restore: only snapshots >in, ignores source
\ identity, i.e. cannot restore accross input sources (or lines)

	: save-input ( -- x1 n )
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

	: restore-input ( x1 .. xn n -- flag )
		dup $2 = if
			drop                 \ x1 x2
			source-id <> if      \ source-id changed => cannot restore
				drop true
			else
				>in ! false 	\ restore >in
			then
		else
			0 ?do drop loop true
		then
	;
