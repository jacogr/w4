require constants.f
require loops.f
require search.f
require search.string.f
require stack.f
require string.f

\ Design:
\ - All semantics expressed in Forth (self-hosting source of truth)
\ - Two stacks in linear memory (header-cell layout):
\     * locals VALUE stack  : actual local values
\     * locals FRAME stack  : saved fp/sp per colon entry
\ - One current frame pointer (fp) stored separately
\ - Every colon entry pushes a frame record
\ - Every colon exit pops a frame record
\ - {: ... :} allocates locals within the current frame

\ Generic helpers for header-cell stacks
\
\ Stack layout (all stacks):
\   [ count ] [ cell0 ] [ cell1 ] ... [ cellN ]

	: stk-count@ ( a-addr -- n ) @ ;
	: stk-count! ( n a-addr -- ) ! ;

	: stk-base ( a-addr -- a-addr' ) cell+ ;
	: stk-addr ( i a-addr -- a-addr' ) stk-base swap cells + ;

	: stk-push ( x a-addr -- )
		\ write value
		swap 				( x a-addr -- a-addr x )
		over stk-count@		( a-addr x -- a-addr x n )
		sp-2@				( a-addr x n -- a-addr x n a-addr )
		stk-addr !			( a-addr x n a-addr -- a-addr )

		\ update count
		dup stk-count@		( a-addr -- a-addr n )
		1+ swap				( a-addr n -- n' a-addr )
		stk-count!			( a-addr n' -- )
	;

	: stk-pop ( a-addr -- x )
		dup >r						( a-addr -- a-addr ) ( r: -- a-addr )
		stk-count@ 1-				( a-addr -- i )
		dup r@ stk-count!			( i -- i ) ( r: a-addr -- a-addr )   \ write new count
		r> stk-addr @				( i a -- x ) ( r: a-addr -- )
	;

\ Locals runtime state helpers

	: locals-sp@ ( -- sp ) (locals-value^) stk-count@ ;
	: locals-sp! ( sp -- ) (locals-value^) stk-count! ;

	: locals-fp@ ( -- fp ) (locals-fp^) @ ;
	: locals-fp! ( fp -- ) (locals-fp^) ! ;

\ Locals FRAME stack (saved fp/sp per colon entry)
\ Each frame record = 2 cells: saved-fp saved-sp

	: locals-push-frame ( -- ) \ called at EVERY colon entry
		locals-fp@ (locals-frame^) stk-push
		locals-sp@ (locals-frame^) stk-push
	;

	: locals-pop-frame ( -- )
  		(locals-frame^) stk-pop locals-sp!
  		(locals-frame^) stk-pop locals-fp!
	;

\ Allocate locals for THIS definition (called by {:} prologue)

	: locals-alloc ( n -- )
		locals-sp@ dup locals-fp!	\ fp = old sp (cell index)
		+ locals-sp!				\ sp += n
	;

\ Local accessors (used by local identifiers)

	: (local-addr) ( i -- a-addr )
		locals-fp@ + 			\ absolute cell index
		(locals-value^) stk-addr
	;

	: (local@) ( i -- n ) (local-addr) @ ;
	: (local!) ( n i -- ) (local-addr) ! ;
	: (to-local) ( n i -- ) (local!) ;

\ Define a local xt which carries the index

	: (local-define) ( c-addr u i -- )
		\ create local xt
		(flg-xt-local)
		(flg-is-imm) or
		(flg-is-vis) or					( c-addr u i -- xt c-addr u i flags )
		(new-xt) -rot					( c-addr u i flags -- xt c-addr u )
		sp-2@ (xt>str+len+hash!)		( xt c-addr u -- xt )

		\ add to locals-wid
		(locals-wid) swap				( xt -- wid xt )
		(lookup-append)					( wid xt -- nt )
		drop							( nt -- )
	;

\ Emit locals initialization prologue
\ Runtime stack already has exactly n init values

	: (locals-compile-prologue) ( n -- )
		\ skip prologue on no values
		dup 0= if (locals-wid!) exit then

		postpone locals-push-frame	( n -- n )
		dup lit,					( n -- n )
		postpone locals-alloc		( n -- n )

		dup 0 ?do
			dup 1- i -				( n -- n i ) \ idx = n-1-i

			lit,
			postpone (local!)
		loop

		drop					( n -- )
	;

	: (locals-compile-epilogue) ( -- )
		postpone locals-pop-frame
	;

\ https://forth-standard.org/standard/locals/LOCAL
\
\ When executed during compilation, (local) passes a message to the
\ system that has one of two meanings. If u is non-zero, the message
\ identifies a new local whose definition name is given by the string
\ of characters identified by c-addr u. If u is zero, the message is
\ "last local" and c-addr has no significance.
\
\ The result of executing (local) during compilation of a definition is
\ to create a set of named local identifiers, each of which is a definition
\ name, that only have execution semantics within the scope of that definition's
\ source.
\
\ (LOCAL) as required by the standard protocol used by {: ... :}
\ During compilation:
\   ( c-addr u ) with u<>0 : declare a local identifier (name) with next index
\   ( c-addr 0 )          : "last local" -> emit prologue and keep locals active
\ Cleanup must happen at ';' (hook (locals-wid) reset there).

	variable (locals#)					\ number of locals in current definition
	variable (locals-count#)			\ number of locals being defined

	: (LOCAL) ( c-addr u -- )
		?dup if							( c-addr u -- c-addr u )
			\ no wordlist?
			(locals-wid) 0= if			( c-addr u -- c-addr u )
				(new-lookup-small) (locals-wid!)
				0 (locals#) !
			then

			\ internal = locals# @
			\ actual   = (locals-max# @ - 1) - internal
			(locals-count#) @ 1-		( c-addr u -- c-addr u max-1 )
			(locals#) @ -				( c-addr u max-1 -- c-addr u actual )

			(local-define)				( c-addr u i -- )

			\ bump number defined
			1 (locals#) +!				( --  )
		else							( c-addr -- c-addr )
			drop						( c-addr -- )

			\ locals started?
			(locals-wid) 0<> if			( --  )
				(locals#) @ (locals-compile-prologue)
			then
		then
	;

\ https://forth-standard.org/standard/locals/bColon
\
\ Execution: Place the value currently assigned to name on the stack. An
\ ambiguous condition exists when name is executed while in interpretation
\ state.

	$beadbead constant (local-undefined-value)

	: (local-match-or-end?) ( c-addr1 u1 c-addr2 u2 -- f )
		sp-2@ 0= >r
		compare 0=
		r> or
	;

	: (local-scan-args)
		\ 0 c-addr1 u1 -- c-addr1 u1 ... c-addrn un n c-addrn+1 un+1
		begin
			2dup s" |" (local-match-or-end?) 0= while
			2dup s" --" (local-match-or-end?) 0= while
			2dup s" :}" (local-match-or-end?) 0= while

			rot 1+ parse-name
		again then then then
	;

	: (local-scan-locals)
		\ n c-addr1 u1 -- c-addr1 u1 ... c-addrn un n c-addrn+1 un+1
		2dup s" |" compare 0= 0= if exit then
		2drop parse-name

		begin
			2dup s" --" (local-match-or-end?) 0= while
			2dup s" :}" (local-match-or-end?) 0= while

			rot 1+ parse-name

			postpone (local-undefined-value)
		again then then
	;

	: (local-scan-end) ( c-addr1 u1 -- c-addr2 u2 )
		begin
			2dup s" :}" (local-match-or-end?) 0= while
			2drop parse-name
		repeat
	;

	: (local-define-locals) ( c-addr1 u1 ... c-addrn un n -- )
		\ store the count for index in (local)
		dup (locals-count#) !

		\ add all locals
		0 ?do (local) loop
		0 0 (local)
	;

	: {: ( -- )
		0 parse-name
		(local-scan-args) (local-scan-locals) (local-scan-end)
		2drop (local-define-locals)
	; immediate

\ https://forth-standard.org/standard/core/Semi
\
\ Append the run-time semantics below to the current definition. End the
\ current definition, allow it to be found in the dictionary and enter
\ interpretation state, consuming colon-sys. If the data-space pointer is
\ not aligned, reserve enough data space to align it.

	' ; constant (xt-orig-;)

	: ; ( -- )
		(locals-wid) 0<> if
			\ compile pop
			postpone locals-pop-frame

			\ clear local usage
			0 (locals-wid!)
			0 (locals#) !
		then

		\ original colon
		(xt-orig-;) execute
	; immediate

	\ : exit ( -- )
	\ 	state @ if
	\ 		(locals-wid) 0<> if
	\ 			postpone locals-pop-frame
	\ 		then

	\ 		postpone exit
	\ 	then
	\ ; immediate

\ INTEGRATION NOTES
\
\ 1) FIND / find-name:
\    search (locals-wid) FIRST if non zero.
\
\ 2) Colon entry (docol):
\      locals-enter
\
\ 3) Colon exit / EXIT:
\      locals-exit
\
\ 4) ';' (end of definition):
\      (locals-wid) set to 0
\
\ With this, nested calls like:
\   foo {: a -- :} ...
\   bar ...
\   baz {: a -- :} ... bar foo to a
\ work correctly and deterministically.
