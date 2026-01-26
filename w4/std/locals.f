require constants.f
require loops.f
require search.f
require search.string.f
require stack.f
require string.f
require string.utils.f

\ allocate memory for locals

	$200 constant (locals-memory-cells) \ 512 cells
	(locals-memory-cells) 1+ cells buffer: (locals-memory^)

	\ max address, TODO check this when moving
	(locals-memory-cells) cells (locals-memory^) + constant (locals-memory-max)

	\ store base offset
	(locals-memory^) (locals-base^) !

\ Local accessors (used by local identifiers)

	: (local-addr-0) ( -- a-addr ) (locals-base^) @ dup @ cells - ;

	: (to-local) ( n i -- ) cells (local-addr-0) + ! ;

\ Enter & exit a locals definition

	: locals-enter ( n -- )
		\ calculate base address for counter
		dup 1+ cells			( n n --  n n' )
		(locals-base^) @ +		( n n' -- n a-addr )

		\ check address, -52 control-flow stack overflow
		dup (locals-memory-max) > #-52 and throw

		\ store locals count & base
		dup (locals-base^) ! !	( n a-addr -- )
	;

	: locals-exit ( -- )
		\ address before offset 0, previous base
		(local-addr-0)			( -- a-addr )
		1 cells -				( a-addr -- a-addr' )

		\ restore previous base addr
		(locals-base^) !
	;

\ Define a local xt which carries the index

	: (local-define) ( c-addr u i -- )
		\ create local xt with name & hash
		(flg-xt-local) (flg-is-vis) or	( c-addr u i -- c-addr u i flags )
		(new-xt-full)					( c-addr u i flags -- xt )

		\ add to locals-wid
		(locals-wid) swap				( xt -- wid xt )
		(lookup-append)	drop			( wid xt -- )
	;

\ Emit locals initialization prologue
\ Runtime stack already has exactly n init values

	: (locals-compile-prologue) ( n -- )
		\ compile `n locals-enter`
		dup lit,					( n -- n )
		postpone locals-enter		( n -- n )

		dup 0 ?do
			dup 1- i -				( n -- n i ) \ idx = n-1-i

			\ compile `i (to-local)`, value expected on stack
			lit,
			postpone (to-local)
		loop

		drop						( n -- )
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

	variable (locals-done#)				\ number of locals done in current definition
	variable (locals-count#)			\ total number of locals being defined

	: (LOCAL) ( c-addr u -- )
		?dup if							( c-addr u -- c-addr u )
			\ no wordlist?
			(locals-wid) 0= if			( c-addr u -- c-addr u )
				(new-lookup-tiny) (locals-wid!)
				1 (locals-done#) !
			else
				1 (locals-done#) +!
			then

			\ calculate index & define
			(locals-count#) @			( c-addr u -- c-addr u max-1 )
			(locals-done#) @ -			( c-addr u max-1 -- c-addr u actual )
			(local-define)				( c-addr u i -- )
		else							( c-addr -- c-addr )
			drop						( c-addr -- )

			\ locals started?
			(locals-wid) 0<> if			( -- )
				(locals-count#) @		( -- n )
				(locals-compile-prologue)
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

	: (local-scan-args) ( 0 c-addr1 u1 -- c-addr1 u1 ... c-addrn un n c-addrn+1 un+1 )
		begin
			2dup s" |" (local-match-or-end?) 0= while
			2dup s" --" (local-match-or-end?) 0= while
			2dup s" :}" (local-match-or-end?) 0= while

			rot 1+ parse-name
		again then then then
	;

	: (local-scan-locals) ( n c-addr1 u1 -- c-addr1 u1 ... c-addrn un n c-addrn+1 un+1 )
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
		0 parse-name				( -- 0 c-addr u )
		(local-scan-args) (local-scan-locals) (local-scan-end)
		2drop (local-define-locals)
	; immediate

\ https://forth-standard.org/standard/core/EXIT
\
\ Return control to the calling definition specified by nest-sys. Before
\ executing EXIT within a do-loop, a program shall discard the loop-control
\ parameters by executing UNLOOP.

	\ : EXIT ( -- )
	\ 	state @ if
	\		\ clear locals (if available)
	\ 		(locals-wid) 0<> if
	\ 			postpone locals-exit
	\ 		then

	\ 		postpone exit
	\	else
	\		\ don't allow in interpret, -25	return stack imbalance
	\		#-25 throw
	\ 	then
	\ ; immediate

\ https://forth-standard.org/standard/core/Semi
\
\ Append the run-time semantics below to the current definition. End the
\ current definition, allow it to be found in the dictionary and enter
\ interpretation state, consuming colon-sys. If the data-space pointer is
\ not aligned, reserve enough data space to align it.

	: ; ( -- )
		(locals-wid) 0<> if
			\ clear local usage
			0 (locals-wid!)

			\ compile locals restore
			\ TODO Change to `exit` when the above goes in
			postpone locals-exit
		then

		\ execute original colon (also immediate)
		postpone ;
	; immediate
