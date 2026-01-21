
require ../std/constants.f
require ../std/text.f

\ Checks for the validity of the addresses, either valid, xt, nt or
\ list. In this the defined flags for the implemetation is used.

	: is-alloc-range? ( n -- f )
		here @ <	( n -- n<here )
	;

	: is-flag? ( n flag -- f ) dup >r and r> = ;

	: is-flagged? ( a-addr flag -- f )
		swap 					( a-addr flag -- flag a-addr )
		dup is-alloc-range? if
			>flags @ 			( flag a-addr -- flag flags )
			swap is-flag?		( flags flag -- f )
		else drop 0 and then
	;

	: is-list? ( addr -- f ) (flg-list) is-flagged? ;

	: is-xt? ( addr -- f ) (flg-set-any) is-flagged? ;

	: is-nt? ( addr -- f )
		dup (flg-name) is-flagged? if
			(name>value@) is-xt?
		else 0 and then
	;

\ https://forth-standard.org/standard/tools/SEE
\
\ Display a human-readable representation of the named word's definition.
\ The source of the representation (object-code decompilation, source block
\  etc.) and the particular form of the display is implementation defined.
\
\ TODO
\	- Proper message when name is not found

	: (u.r-tab) ( u -- ) #12 u.r ;

	: (u.r-tabd) ( u -- ) #12 u.rd ;

	: (.r-tab) ( u -- ) #12 .r ;

	\ hack blank with actual offsets inside the buffer (one past .)
	: (see-text-skip) space s"             " type ;
	: (see-text-imm.) space ." [imm.] " ;

	: (see-xt) ( a-addr -- )
		dup (u.r-tab)						( a-addr -- a-addr )
		dup (xt>flags@)						( a-addr -- a-addr flags )

		\ display flags
		\ dup (u.r-tab)						( a-addr flags -- a-addr flags )

		dup (flg-xt-lit) is-flag? if		( a-addr flags -- a-addr flags )
			(flg-set-var) is-flag? if		( a-addr flags -- a-addr ) \ variation?
				dup (xt>value@) (u.r-tabd)	( a-addr -- a-addr )
			else
				dup (xt>value@) (u.r-tab)	( a-addr -- a-addr )
			then
		else								( a-addr flags -- a-addr flags )
			(flg-xt-does) is-flag? if		( a-addr flags -- a-addr )
				dup (xt>value@) (u.r-tab)	( a-addr -- a-addr )
			else
				(see-text-skip)				( a-addr -- a-addr )
			then
		then

		>str+len	type 						( a-addr -- )
	;

	: (see-list) ( a-addr -- )
		dup is-list? if
			(list>owner@)					( list -- owner )
			dup is-xt? if
				space '~' emit space
				>str+len type
			else drop then
		else drop then
	;

	: (see-nt) ( a-addr -- ) (name>value@) (see-xt) ;

	: see ( "name" -- )
		base @ hex						( -- base )
		parse-name find-name 			( base -- base nt )
		(name>value@)					( base nt -- base xt )

		cr (see-text-skip)
		dup (see-xt)					( base xt -- base xt )

		dup (xt>flags@) (flg-set-imm) is-flag? if
			(see-text-skip)
			(see-text-imm.)
		then

		cr

		dup (xt>flags@) (flg-xt-tkn) is-flag? if
			(xt>value@) (list>head@)	( base xt -- base head-nt )
			begin
			 	dup (u.r-tab)			( base nt -- base nt )
				dup (see-nt) cr			( base nt -- base nt )
				(name>next@) dup 0=		( base nt -- base next-nt )
			until
			drop						( base 0 -- base )
		else drop then					( base xt -- base )

		cr
		base !							( base -- )
	;

\ https://forth-standard.org/standard/tools/DotS
\
\ Copy and display the values currently on the data stack. The format of
\ the display is implementation-dependent.

	: (.s-cell) ( addr -- )
		dup (u.r-tab)						( addr -- addr )
		@ dup (.r-tab)						( addr -- val )

		dup is-xt? if						( val -- val )
			(see-xt)						( val -- )
		else
			dup is-nt? if					( val -- val )
				dup (see-nt)				( val -- val )
				(name>link@) (see-list)		( val -- )
			else drop then					( val -- )
		then
	;

	: (.s) ( a-addr off c-addr u -- )
		cr type					( a-addr off c-addr u -- a-addr off )
		swap base @ swap		( a-addr off -- off base a-addr )
		dup @ sp-3@ -			( off base a-addr -- off base a-addr count )

		decimal
		space dup u. cr	hex

		dup 0> if				( off base a-addr count -- off base a-addr count )
			0 do				( off base a-addr count -- off base a-addr )
				decimal i (u.r-tab) hex			\ cell index
				i 1+ cells sp-1@ + (.s-cell)	\ cell address
				cr
			loop
		else drop then			( off base a-addr count -- off base a-addr )

		drop					( off base a-addr -- off base )
		base !					( off base -- off )
		drop					( off -- )
	;

	: .s ( -- ) (sp^) #3 s" data stack " (.s) ;

	: .sc ( -- ) (cp^) #0 s" ctrl stack " (.s) ;

	: (.sr) ( -- ) (rp^) #2 s" rtrn stack " (.s) ;

	: .sr ( -- ) (.sr) ;

	: .sa ( -- ) .s .sc (.sr) ;

\ https://forth-standard.org/standard/tools/WORDS
\
\ List the definition names in the first word list of the search order.
\ The format of the display is implementation-dependent.
\
\ TODO
\	- remove (words-count) when we have actual locals

	variable (words-count)

	: (words-nt-shown?) ( nt -- f )
		(name>value@)					( nt -- xt )
		dup (name>flags@)				( xt -- xt flags )

		\ visible?
		(flg-set-vis) is-flag? if 		( xt flags -- xt )
			>str+len						( xt -- c-addr u )
			sp-1@ c@ '('  =				( c-addr u -- c-addr u f1 )		\ f1 = startsWith (
			-rot						( c-addr u f1 -- f1 c-addr u )
			1- + c@ ')' =				( f1 c-addr u -- f1 f2 )		\ f2 = endsWith )
			and	0=						( f2 f1 -- f )					\ f = (f1 & f2) == 0
		else
			drop false					( xt -- false )
		then
	;

	: words ( -- )
		base @ hex
		cr

		\ init counter, set list start
		0 (words-count) !
		(dict^) (list>head@)

		begin
			\ show nt?
			dup (words-nt-shown?) if			( nt -- nt )

				\ increment count
				1 (words-count) +!

				\ get xt
				dup (name>value@)				( nt -- nt xt )

				\ display name
				dup >str+len type				( nt xt -- nt xt )

				\ show immediate?
				(xt>flags@)						( nt xt -- nt flags )
				(flg-set-imm) is-flag? if		( nt flags -- nt )
					(see-text-imm.)
				then

				#3 spaces
			then

			\ check next for zero
			(name>next@) dup 0=					( nt -- nt' f )
		until

		drop									( nt -- )

		decimal
		cr cr ." words: "
		base @ decimal (words-count) @ . base !
		cr cr
		base !
	;
