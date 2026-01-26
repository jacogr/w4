require constants.f
require loops.f
require search.f
require search.string.f
require stack.f
require string.f

\ Local accessors (used by local identifiers)

	: (local-addr-0) ( -- a-addr )
		(locals-base^) @ 	( -- a-addr )
		dup @				( a-addr -- a-addr n )
		cells -				( a-addr n -- a-addr' )
	;

	: (local-addr) ( i -- a-addr )
		(local-addr-0) 		( i -- a-addr )
		swap cells +		( i a-addr -- a-addr' )
	;

	: (local@) ( i -- n ) (local-addr) @ ;
	: (local!) ( n i -- ) (local-addr) ! ;
	: (to-local) ( n i -- ) (local!) ;

\ Enter & exit a locals definition

	: locals-enter ( n -- )
		\ calculate base address for counter
		dup 1+ cells			( n n --  n n' )
		(locals-base^) @ +		( n n' -- n a-addr )

		\ store locals count
		swap over !		 		( n a-addr -- a-addr )

		\ store new base address
		(locals-base^) !		( a-addr -- )
	;

	: locals-exit ( -- )
		\ address before offset 0, previous base
		(local-addr-0)			( -- a-addr )
		1 cells -				( a-addr -- a-addr' )

		\ store previous base addr
		(locals-base^) !
	;

\ Define a local xt which carries the index

	: (local-define) ( c-addr u i -- )
		\ create local xt
		(flg-xt-local) (flg-is-vis) or	( c-addr u i -- xt c-addr u i flags )
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

		\ compile `n locals-enter`
		dup lit,					( n -- n )
		postpone locals-enter		( n -- n )

		dup 0 ?do
			dup 1- i -				( n -- n i ) \ idx = n-1-i

			lit,
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
\ Cleanup must happen at ';' (hook (locals-wid) reset there).

	variable (locals#)					\ number of locals in current definition
	variable (locals-count#)			\ number of locals being defined

	: (LOCAL) ( c-addr u -- )
		?dup if							( c-addr u -- c-addr u )
			\ no wordlist?
			(locals-wid) 0= if			( c-addr u -- c-addr u )
				(new-lookup-tiny) (locals-wid!)
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
				(locals-count#) @ (locals-compile-prologue)
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
		\ ensure we have a sane amount of locals
		dup (env-locals#) > #-8 and throw

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
			postpone locals-exit

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
	\ 			postpone locals-exit
	\ 		then

	\ 		postpone exit
	\ 	then
	\ ; immediate
