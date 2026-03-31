m4_require(<!std/compile.f!>)
m4_require(<!std/constants.f!>)
m4_require(<!std/logic.f!>)
m4_require(<!std/control.f!>)
m4_require(<!std/stack-base.f!>)
m4_require(<!std/stack-ptr.f!>)
m4_require(<!std/stack-rs.f!>)
m4_require(<!std/string.f!>)

\ https://forth-standard.org/standard/core/SOURCE
\
\ c-addr is the address of, and u is the number of characters in
\ the input buffer.

	: SOURCE (source^) @ >str+len ;

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
				$0 sp-4!		( ch -1 start cur rem -- ch 0 start cur rem )
			else
				1- swap			( ch -1 start cur rem -- ch -1 start rem' cur ) \ rem' = rem - 1
				1+ swap 		( ch -1 start cur rem -- ch -1 start cur' rem' ) \ cur' = cur + 1
			then
		repeat

		swap					( ch -1|0 start cur rem -- ch -1|0 start rem cur )
		sp-2@ -					( ch -1|0 start rem curr -- ch -1|0 start rem u ) ( r: in0 -- in0 ) \ u = cur - start

		over 0<> negate			( ch -1|0 start rem u -- ch -1|0 start rem u 1|0 ) \ found = (rem != 0) ? 1 : 0
		over +					( ch -1|0 start rem u 1|0 -- ch -1|0 start rem u u' ) \ u' = 1|0 + u
		r@ +					( ch -1|0 start rem u u' -- ch -1|0 start cur rem u newin ) ( r: in0 -- in0 ) \ newin = u' + in0

		>in !					( ch -1|0 start rem u newin -- ch -1|0 start cur rem u )

		swap drop				( ch -1|0 start rem u -- ch -1|0 start u )
		sp-2!					( ch -1|0 start u -- ch u start )
		sp-2!					( ch u start -- start u )

		r> drop					( r: in0 -- )
	;

\ https://forth-standard.org/standard/core/PARSE-NAME
\
\ Skip leading space delimiters. Parse name delimited by a space.
\
\ c-addr is the address of the selected string within the input buffer
\ and u is its length in characters. If the parse area is empty or contains
\ only white space, the resulting string has length zero.

	: (parse-whitespace-skip) ( -- )
		begin
			>in @ source nip u<
		while
			source drop >in @ + c@
			#33 u<
		while
			$1 >in +!
		repeat then
	;

	: (parse-token,patched) ( delim -- c-addr u )
		dup #33 u< if
			drop
			(parse-whitespace-skip)

			\ start = source-base + >in
			source drop >in @ + dup

			\ scan until end-of-source or next whitespace
			begin
				>in @ source nip u< if
					source drop >in @ + c@ #33 u< 0=
				else false then
			while
				$1 >in +!
			repeat

			\ u = cur - start
			source drop >in @ + swap -

			\ consume one delimiter when present (PARSE-compatible >in advance)
			>in @ source nip u< if
				$1 >in +!
			then
		else parse then
	; patch parse-token

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

	: (find-flag-xt) ( xt -- xt f )
		dup is-xt-immediate?	( xt -- xt f )
		$1 $-1 select			\ -1 normal, 1 immediate
	;

	: FIND ( c-addr -- c-addr 0 | xt 1 | xt -1 )
		dup >r					( c-addr -- c-addr ) ( r: -- c-addr )
		count find-name			( c-addr -- nt | 0 )

		dup 0= if
			drop				( 0 -- )
			r> $0				( -- c-addr 0 )
		else
			r> drop
			(nt>value@)			( nt -- xt )
			(find-flag-xt)		( xt -- xt f )
		then
	;

\ https://forth-standard.org/standard/core/SAVE-INPUT
\
\ ( -- xn ... x1 n ) x1 through xn describe the current state of the input
\ source specification for later use by RESTORE-INPUT.
\
\ Minimal (evaluate-friendly) save/restore: only snapshots >in, ignores source
\ identity, i.e. cannot restore accross input sources (or lines)

	$2 cells buffer: (save-input-off)
	$100 constant (savei-in-size#)
	$400 constant (savei-ln-size#)

	$0 constant (savei-sid#)
	$1 constant (savei-in#)
	$2 constant (savei-fdlo#)
	$3 constant (savei-fdhi#)
	$4 constant (savei-ln-len#)
	$5 constant (savei-ln-pos#)
	$6 constant (savei-in-len#)
	$7 constant (savei-in-pos#)
	$8 constant (savei-eof#)
	$9 constant (savei-row#)
	$a constant (savei-meta#)

	: (savei-size#) ( -- u )
		(savei-meta#) cells
		(savei-ln-size#) 1+ +
		(savei-in-size#) 1+ +
	;

	: (savei-cell^) ( frame idx -- a-addr ) cells + ;
	: (savei@) ( frame idx -- u ) (savei-cell^) @ ;
	: (savei!) ( u frame idx -- ) (savei-cell^) ! ;

	: (savei-ln^) ( frame -- c-addr ) (savei-meta#) cells + ;
	: (savei-in^) ( frame -- c-addr ) (savei-ln^) (savei-ln-size#) 1+ + ;

	: (save-input-file) ( fid -- frame n )
		align here >r
		(savei-size#) allot

		dup r@ (savei-sid#) (savei!)
		>in @ r@ (savei-in#) (savei!)

		(save-input-off) over (fid>fd@) wasi::fd_tell drop
		(save-input-off) @ r@ (savei-fdlo#) (savei!)
		(save-input-off) cell+ @ r@ (savei-fdhi#) (savei!)

		dup (fid>ln-len@) r@ (savei-ln-len#) (savei!)
		dup (fid>ln-pos@) r@ (savei-ln-pos#) (savei!)
		dup (fid>in-len@) r@ (savei-in-len#) (savei!)
		dup (fid>in-pos@) r@ (savei-in-pos#) (savei!)
		dup (fid>is-eof@) r@ (savei-eof#) (savei!)
		dup (fid>row@) r@ (savei-row#) (savei!)

		dup (fid>ln-ptr@) r@ (savei-ln^) (savei-ln-size#) 1+ move
		dup (fid>in-ptr@) r@ (savei-in^) (savei-in-size#) 1+ move
		drop

		r> $1
	;

	: (restore-input-file) ( frame -- flag )
		dup (savei-sid#) (savei@) dup >r
		source-id <> if
			drop r> drop true exit
		then

		dup (savei-fdlo#) (savei@) (save-input-off) !
		dup (savei-fdhi#) (savei@) (save-input-off) cell+ !

		r@ (fid>fd@)
		(save-input-off) @
		(save-input-off) cell+ @
		$0 (save-input-off)
		wasi::fd_seek
		if
			drop r> drop true exit
		then

		dup (savei-ln-len#) (savei@) r@ (fid>ln-len!)
		dup (savei-ln-pos#) (savei@) r@ (fid>ln-pos!)
		dup (savei-in-len#) (savei@) r@ (fid>in-len!)
		dup (savei-in-pos#) (savei@) r@ (fid>in-pos!)
		dup (savei-eof#) (savei@) r@ (fid>is-eof!)
		dup (savei-row#) (savei@) r@ (fid>row!)

		dup (savei-ln^) r@ (fid>ln-ptr@) (savei-ln-size#) 1+ move
		dup (savei-in^) r@ (fid>in-ptr@) (savei-in-size#) 1+ move

		dup (savei-in#) (savei@) >in !
		drop r> drop false
	;

	: SAVE-INPUT ( -- x1 n )
		source-id dup 0<> over $-1 <> and if
			dup (fid>flags@) if
				(save-input-file) exit
			then
		then

		drop >in @ source-id $2
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
		dup $1 = if
			drop
			(restore-input-file)
		else dup $2 = if
			drop                 \ x1 x2
			source-id <> if      \ source-id changed => cannot restore
				drop true
			else
				>in ! false 	\ restore >in
			then
		else $0 ?do drop loop true then then
	;
