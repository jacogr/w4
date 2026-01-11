require w4/std/compile.f
require w4/std/text.f

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

\ https://forth-standard.org/standard/tools/SEE
\
\ TODO
\	- Proper message when name is not found

	: is-alloc-range? ( n -- f )
		dup here @ <	( n -- n n<here )
		swap dup 0> 	( n n<here -- n<here n n>0 )
		swap $3 and 0=	( n<here n n>0 -- n<here n>0 n%4=0 )
		and and			( n<here n>0 n%4=0 -- f )
	;

	: is-flag? ( n flag -- f ) dup >r and r> = ;

	: is-flagged? ( a-addr flag -- f )
		swap 				( a-addr flag -- flag a-addr )
		dup is-alloc-range? if
			>flags @ 		( flag a-addr -- flag flags )
			swap is-flag?	( flags flag -- f )
		else drop 0 and then
	;

	: is-list? ( addr -- f ) (flg-list) is-flagged? ;

	: is-xt? ( addr -- f ) (flg-set-any) is-flagged? ;

	: is-nt? ( addr -- f )
		dup (flg-name) is-flagged? if
			name>xt is-xt?
		else 0 and then
	;

	: (u.r-tab) ( u -- ) #12 u.r ;

	: (u.r-tabd) ( u -- ) #12 u.rd ;

	: (u.r-tab2) ( u -- ) #21 u.r2 ;

	: (.r-tab) ( u -- ) #12 .r ;

	\ hack blank with actual offsets inside the buffer (one past .)
	: (see-text-skip) space s" .            " swap 1+ swap 1- type ;
	: (see-text-imm.) space ." [imm.] " ;

	: (see-xt) ( a-addr -- )
		dup (u.r-tab)						( a-addr -- a-addr )
		dup >flags @						( a-addr -- a-addr flags )

		\ display flags
		\ dup (u.r-tab)						( a-addr flags -- a-addr flags )

		dup (flg-xt-lit) is-flag? if		( a-addr flags -- a-addr flags )
			(flg-set-var) is-flag? if		( a-addr flags -- a-addr ) \ variation?
				dup >body @ (u.r-tabd)		( a-addr -- a-addr )
			else
				dup >body @ (u.r-tab)		( a-addr -- a-addr )
			then
		else								( a-addr flags -- a-addr flags )
			(flg-xt-does) is-flag? if		( a-addr flags -- a-addr )
				dup >body @ (u.r-tab)		( a-addr -- a-addr )
			else
				(see-text-skip)					( a-addr -- a-addr )
			then
		then

		>string	type 						( a-addr -- )
	;

	: (see-list) ( a-addr -- )
		dup is-list? if
			list>owner						( list -- owner )
			dup is-xt? if
				space '~' emit space
				>string type
			else drop then
		else drop then
	;

	: (see-nt) ( a-addr -- ) name>xt (see-xt) ;

	: see ( "name" -- )
		base @ hex						( -- base )
		parse-name find-name name>xt	( base -- xt )

		cr (see-text-skip)
		dup (see-xt)					( base xt -- base xt )

		dup >flags @ (flg-set-imm) is-flag? if
			(see-text-skip)
			(see-text-imm.)
		then

		cr

		dup >flags @ (flg-xt-tkn) is-flag? if
			>body @ list>head			( base xt -- base head-nt )
			begin
			 	dup (u.r-tab)			( base nt -- base nt )
				dup (see-nt) cr			( base nt -- base nt )
				name>next dup 0=		( base nt -- base next-nt )
			until
			drop						( base 0 -- base )
		else drop then					( base xt -- base )

		cr
		base !							( base -- )
	;

\ https://forth-standard.org/standard/tools/DotS

	: (.s-cell) ( addr -- )
		dup (u.r-tab)					( addr -- addr )
		@ dup (.r-tab)					( addr -- cont )

		dup is-xt? if					( cont -- cont )
			(see-xt)					( cont -- )
		else
			dup is-nt? if				( cont -- cont )
				dup (see-nt)			( cont -- cont )
				name>list (see-list)	( cont -- )
			else drop then				( cont -- )
		then
	;

	: (.s) ( a-addr off c-addr u -- )
		cr type				( a-addr off c-addr u -- a-addr off )
		swap base @ swap	( a-addr off -- off base a-addr )
		dup @ sp-3@ -		( off base a-addr -- off base a-addr count )
		decimal space dup u. cr	hex

		dup 0> if			( off base a-addr count -- off base a-addr count )
			0 do			( off base a-addr count -- off base a-addr )
				decimal i (u.r-tab) hex			\ cell index
				i 1+ cells sp-1@ + (.s-cell)	\ cell address
				cr
			loop
		else drop then		( off base a-addr count -- off base a-addr )

		drop				( off base a-addr -- off base )
		base !				( off base -- off )
		drop				( off -- )
	;

	: .s ( -- ) (sp^) #3 s" data stack " (.s) ;

	: .sc ( -- ) (cp^) #0 s" ctrl stack " (.s) ;

	: (.sr) ( -- ) (rp^) #0 s" rtrn stack " (.s) ;

	: .sr ( -- ) (.sr) ;

	: .sa ( -- ) .s .sc (.sr) ;

\ https://forth-standard.org/standard/tools/WORDS
\
\ TODO
\	- remove (words-count) when we have actual locals

	variable (words-count)

	: words ( -- )
		base @ hex
		cr

		\ init counter, set list start
		0 (words-count) !
		(dict^) list>head

		begin
			\ increment count
			(words-count) @ 1+ (words-count) !

			\ output xt info twice (name & immediate?)
			dup name>xt dup

			>string type
			>flags @ (flg-set-imm) is-flag? if
				(see-text-imm.)
			then

			#3 spaces

			\ check next for zero
			name>next dup 0=
		until

		drop

		decimal
		cr cr ." words: "
		base @ decimal (words-count) @ . base !
		cr cr
		base !
	;
