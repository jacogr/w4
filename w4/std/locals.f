require loops.f
require search.f
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

	: stk-count@   ( a -- n ) @ ;
	: stk-count!   ( n a -- ) ! ;

	: stk-base     ( a -- a' ) cell+ ;              \ first data cell
	: stk-addr     ( i a -- a_i ) swap cells + stk-base + ;

	: stk-push     ( x a -- )
		dup stk-count@ over stk-addr !
		dup stk-count@ 1+ swap stk-count!
	;

	: stk-pop      ( a -- x )
		dup stk-count@ 1- dup >r
		over stk-count!
		r> swap stk-addr @
	;

\ Locals runtime state helpers

	: locals-sp@   ( -- sp ) (locals-value^) stk-count@ ;
	: locals-sp!   ( sp -- ) (locals-value^) stk-count! ;

	: locals-fp@   ( -- fp ) (locals-fp^) @ ;
	: locals-fp!   ( fp -- ) (locals-fp^) ! ;

\ Locals FRAME stack (saved fp/sp per colon entry)
\ Each frame record = 2 cells: saved-fp saved-sp

	: locals-enter ( -- )    \ called at EVERY colon entry
		locals-fp@ (locals-frame^) stk-push
		locals-sp@ (locals-frame^) stk-push
	;

	: locals-exit  ( -- )    \ called at EVERY colon exit
		(locals-frame^) stk-pop locals-sp!
		(locals-frame^) stk-pop locals-fp!
	;

\ Allocate locals for THIS definition (called by {:} prologue)

	: (local-enter) ( n -- )
		locals-sp@ dup locals-fp!    \ fp = old sp (cell index)
		+ locals-sp!                 \ sp += n
	;

\ Local accessors (used by local identifiers)

	: (local-addr) ( i -- a-addr )
		locals-fp@ +                 \ absolute cell index
		(locals-value^) stk-addr
	;

	: (local@)     ( i -- x ) (local-addr) @ ;
	: (local!)     ( x i -- ) (local-addr) ! ;

\ Compile-time locals bookkeeping

	variable (locals-active)        \ 0 / -1
	variable (locals#)              \ number of locals in current definition

	: (locals-reset) ( -- )         \ called at ';'
		0 (locals-active) !
		0 (locals#) !
		0 (locals-wid!)
	;

\ Define one local identifier (VALUE-like)
\ Body layout:
\   cell 0 : executor for TO   (local!)
\   cell 1 : local index

	: (local-define) ( c-addr u i -- )
		(locals-wid) set-current
		create
			['] (local!) ,      \ executor used by TO
			,                   \ local index
		does>
			cell+ @ (local@)
	;

\ Emit locals initialization prologue
\ Runtime stack already has exactly n init values

	: (locals-compile-prologue) ( n -- )
		postpone literal
		postpone (local-enter)

		dup 0 ?do
			dup 1- i -			( n -- n' ) \ idx = n-1-i

			postpone literal
			postpone (local!)
		loop

		drop					( n -- )
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
\ Cleanup must happen at ';' (hook (locals-reset) there).

	: (LOCAL) ( c-addr u -- )
		?dup 0<> if						( c-addr u -- c-addr u )
			(locals-active) @ 0= if		( c-addr u -- c-addr u )
				wordlist (locals-wid!)
				-1 (locals-active) !
				0 (locals#) !
			then

			(locals#) @					( c-addr u -- c-addr u i )
			1 (locals#) +!				( c-addr u i -- c-addr u )
			(local-define)				( c-addr u -- )
		else							( c-addr -- c-addr )
			drop						( c-addr -- )
			(locals#) @ (locals-compile-prologue)
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
		0 ?do (local) loop
		0 0 (local)
	;

	: {: ( -- )
		0 parse-name
		(local-scan-args) (local-scan-locals) (local-scan-end)
		2drop (local-define-locals)
	; immediate

\ INTEGRATION NOTES
\
\ 1) FIND / find-name:
\    If (locals-active) is true, search (locals-wid) FIRST.
\
\ 2) Colon entry (docol):
\      locals-enter
\
\ 3) Colon exit / EXIT:
\      locals-exit
\
\ 4) ';' (end of definition):
\      (locals-reset)
\
\ With this, nested calls like:
\   foo {: a -- :} ...
\   bar ...
\   baz {: a -- :} ... bar foo to a
\ work correctly and deterministically.
