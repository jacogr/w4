m4_require_w4(`std/constants.f')
m4_require_w4(`std/control.f')
m4_require_w4(`std/search-string.f')
m4_require_w4(`std/stack.f')
m4_require_w4(`std/string.f')
m4_require_w4(`std/string-utils.f')

m4_require_w4(`ext/list.f')

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
		\ compile n locals-enter
		dup lit,					( n -- n )
		postpone locals-enter		( n -- n )

		dup 0 ?do
			\ compile i (to-local), value expected at runtime
			i lit,
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

	variable (locals#)					\ number of locals done in current definition

	: (LOCAL) ( c-addr u -- )
		?dup if							( c-addr u -- c-addr u )
			\ no wordlist?
			(locals-wid) 0= if			( c-addr u -- c-addr u )
				(new-lookup-tiny) (locals-wid!)

				\ clear count
				0 (locals#) !
			then

			\ define with index
			(locals#) @
			(local-define)				( c-addr u i -- )
			1 (locals#) +!
		else							( c-addr -- c-addr )
			drop						( c-addr -- )

			\ locals started?
			(locals-wid) 0<> if			( -- )
				(locals#) @		( -- n )
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

	: (local-parse-next) ( n c-addr u -- c-addr u n' c-addr1 u1 )
		>r swap		( n c-addr u -- c-addr n ) ( r: -- u )
		r> swap 	( c-addr n -- c-addr u n ) ( r: u -- )
		1+			( c-addr u n -- c-addr u n' )	\ n = n + 1
		parse-name	( c-addr u n' -- c-addr u n c-addr1 u1 )
	;

	: (local-scan-args) ( 0 c-addr1 u1 -- c-addr1 u1 ... c-addrn un n c-addrn+1 un+1 )
		begin
			2dup s" |" (local-match-or-end?) 0= while
			2dup s" --" (local-match-or-end?) 0= while
			2dup s" :}" (local-match-or-end?) 0= while
			(local-parse-next)
		again then then then
	;

	: (local-scan-locals) ( n c-addr1 u1 -- c-addr1 u1 ... c-addrn un n c-addrn+1 un+1 )
		2dup s" |" compare 0= 0= if exit then
		2drop parse-name

		begin
			2dup s" --" (local-match-or-end?) 0= while
			2dup s" :}" (local-match-or-end?) 0= while
			(local-parse-next)

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
		\ ensure we can handle this count, -8 dictionary overflow
		dup (env-locals#) > #-8 and throw

		\ add all locals
		0 ?do (local) loop
		0 0 (local)
	;

	: {: ( -- )
		\ new index for this occurence (allows for nested, eg. does>)
		0 (locals#) !

		\ parse & define
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
			\
			\ TODO
			\   - Change to EXIT when the above EXIT goes in
			\ 	- Wasm runtime always compiles original exit, so
			\	  below cannot be EXIT until it applies latest
			postpone locals-exit
		then

		\ execute original colon (also immediate)
		postpone ;
	; immediate
