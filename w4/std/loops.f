require compile.f
require logic.f
require stack.f

\ Conditional branch when top of stack is 0
\ (Standard in older versions of ANS Forth, not in 2012)

	: ?branch ( f dst -- )
		swap 0<>		( f dst -- dst t|f )
		r@				( dst t|f -- dst t|f ret )
		rot				( dst t|f ret -- t|f ret dst )
		select			( t|f ret dst -- ret|dst )
		r!				\ overwrite return with correct value
	;

\ (mark) returns the address of the last compiled literal cell (the one to patch).
\ (resolve) patches that literal cell to the current fallthrough address (r@).

	: (mark) ( C: -- orig )
		-1 lit,						\ placeholder
		(latest>prev^) 				\ get placeholder address
		>cs							( c: -- orig )
	;

	: (resolve) ( a-addr -- )
		cs>						( c: orig -- )
		name>xt >value			\ load placeholder body
		(latest>tail^) swap !	\ write tail location
	;

\ https://forth-standard.org/standard/tools/AHEAD
\
\ Put the location of a new unresolved forward reference orig onto the
\ control flow stack. Append the run-time semantics given below to the
\ current definition. The semantics are incomplete until orig is resolved
\ (e.g., by THEN).
\
\ At runtime: Continue execution at the location specified by the resolution of orig.

	: ahead  ( C: -- orig )
		(mark)
		postpone branch
	; immediate

\ https://forth-standard.org/standard/core/IF
\
\ Put the location of a new unresolved forward reference orig onto the
\ control flow stack. Append the run-time semantics given below to the
\ current definition. The semantics are incomplete until orig is resolved,
\ e.g., by THEN or ELSE.
\
\ At runtime: If all bits of x are zero, continue execution at the location
\ specified by the resolution of orig.

	: if  ( C: -- orig )
		(mark)
		postpone ?branch
	; immediate

\ https://forth-standard.org/standard/core/THEN
\
\ Append the run-time semantics given below to the current definition. Resolve
\ the forward reference orig using the location of the appended run-time
\ semantics.
\
\ At runtime: Continue execution.

	: then  ( C: orig -- )
		(resolve)
	; immediate

\ https://forth-standard.org/standard/core/ELSE
\
\ Put the location of a new unresolved forward reference orig2 onto the
\ control flow stack. Append the run-time semantics given below to the
\ current definition. The semantics will be incomplete until orig2 is resolved
\ (e.g., by THEN). Resolve the forward reference orig1 using the location
\ following the appended run-time semantics.
\
\ At runtime: Continue execution at the location given by the resolution
\ of orig2.

	: else ( c: orig1 -- orig2 )
		postpone ahead	( c: orig1 -- orig1 orig2 )
		cs-swap			( c: orig1 -- orig2 orig1 )
		postpone then	( c: orig2 orig1 -- orig2 )
	; immediate

\ https://forth-standard.org/standard/core/BEGIN
\
\ Put the next location for a transfer of control, dest, onto the control
\ flow stack. Append the run-time semantics given below to the current
\ definition.
\
\ At runtime: Continue execution.

	: begin ( -- ) ( c: -- r-top )
		(latest>tail^) >cs		( c:  -- r-top )
	; immediate

\ https://forth-standard.org/standard/core/UNTIL
\
\ Append the run-time semantics given below to the current definition,
\ resolving the backward reference dest.
\
\ At runtime: If all bits of x are zero, continue execution at the location
\ specified by dest.

	: until ( c: r-top -- ) ( test -- )
		cs> lit,
		postpone ?branch	( test -- )
	; immediate

\ https://forth-standard.org/standard/core/WHILE
\
\ Put the location of a new unresolved forward reference orig onto the
\ control flow stack, under the existing dest. Append the run-time semantics
\ given below to the current definition. The semantics are incomplete until
\ orig and dest are resolved (e.g., by REPEAT).
\
\ If all bits of x are zero, continue execution at the location specified by
\ the resolution of orig.

	: while  ( C: dest -- orig dest )
		postpone if
		cs-swap		\ 1 cs-roll in canonical
	; immediate

\ https://forth-standard.org/standard/core/AGAIN
\
\ Append the run-time semantics given below to the current definition,
\ resolving the backward reference dest.
\
\ At runtime: Continue execution at the location specified by dest. If no
\ other control flow words are used, any program code after AGAIN will not
\ be executed.

	: again  ( -- ) ( C: r-top -- )
		cs> lit,
		postpone branch	\ unconditional jump to r-top
	; immediate

\ https://forth-standard.org/standard/core/REPEAT
\
\ Append the run-time semantics given below to the current definition,
\ resolving the backward reference dest. Resolve the forward reference orig
\ using the location following the appended run-time semantics.
\
\ At runtime: Continue execution at the location given by dest.

	: repeat  ( C: orig dest -- )
		postpone again
		postpone then
	; immediate

\ https://forth-standard.org/standard/core/I
\
\ n | u is a copy of the current (innermost) loop index. An ambiguous condition
\ exists if the loop control parameters are unavailable.

	: i ( -- i ) ( r: u i ret ) r-1@ ;

\ https://forth-standard.org/standard/core/J
\
\ n | u is a copy of the next-outer loop index. An ambiguous condition exists if
\ the loop control parameters of the next-outer loop, loop-sys1, are unavailable.

	: j ( -- j ) ( r: exit-j u' j exit-i u i ret ) r-4@ ;

\ https://forth-standard.org/standard/core/LEAVE
\
\ Discard the current loop control parameters. An ambiguous condition exists if
\ they are unavailable. Continue execution immediately following the innermost
\ syntactically enclosing DO...LOOP or DO...+LOOP.

	: leave ( r: exit-dst u i ret -- exit-dst u i exit-dst )
		r-3@ r!		\ no branch, extra indirection breaks number of return items
	;

\ https://forth-standard.org/standard/core/UNLOOP
\
\ Discard the loop-control parameters for the current nesting level. An UNLOOP
\ is required for each nesting level before the definition may be EXITed. An
\ ambiguous condition exists if the loop-control parameters are unavailable.

	: unloop ( r: exit-dst u i ret -- )
		r>			( -- ret ) ( r: exit-dst u i ret -- exit-dst u i )
		2r> 2drop	( ret -- ret ) ( r: exit-dst u i -- exit-dst )
		r!			( ret -- ) ( r: exit-dst -- ret )
	;

\ https://forth-standard.org/standard/core/DO
\
\ Place do-sys onto the control-flow stack. Append the run-time semantics
\ given below to the current definition. The semantics are incomplete until
\ resolved by a consumer of do-sys such as LOOP.
\
\ Set up loop control parameters with index n2 | u2 and limit n1 | u1. An
\ ambiguous condition exists if n1 | u1 and n2 | u2 are not both the same type.
\ Anything already on the return stack becomes unavailable until the loop-
\ control parameters are discarded.

	: (do) ( u i exit-dst -- ) ( r: -- exit-dst u i ret )
		r>			( u i exit-dst -- u i exit-dst ret ) ( r: ret -- )
		swap		( u i exit-dst ret -- u i ret exit-dst )
		>r 			( u i ret exit-dst -- u i ret ) ( r: -- exit-dst )
		-rot		( u i ret -- ret u i )
		2>r			( ret u i -- ret ) ( r: exit-dst -- exit-dst u i )
		>r			( ret -- ) ( r: exit-dst u i -- exit-dst u i ret )
	;

	: (loop-open)
		postpone (do)		\ runtime: set up loop frame
		postpone begin
	;

	: (loop-close)
		postpone until
		postpone then
		postpone unloop		\ run-time drop loop frame
	;

	: do    ( u i -- ) ( C: -- dest )
		(mark)				\ emits dest literal; pushes orig on CS
		(loop-open)
	; immediate

\ https://forth-standard.org/standard/core/qDO
\
\ Put do-sys onto the control-flow stack. Append the run-time semantics
\ given below to the current definition. The semantics are incomplete until
\ resolved by a consumer of do-sys such as LOOP.
\
\ At runtime: If n1 | u1 is equal to n2 | u2, continue execution at the location
\ given by the consumer of do-sys. Otherwise set up loop control parameters with
\ index n2 | u2 and limit n1 | u1 and continue executing immediately following ?DO.
\ Anything already on the return stack becomes unavailable until the loop control
\ parameters are discarded. An ambiguous condition exists if n1 | u1 and n2 | u2 are
\ not both of the same type.

	: ?do ( u i -- ) ( C: -- orig dest )
		postpone 2dup		( u i -- u i u i)
		postpone =			( u i u i -- u i f )
		(mark)				( u i f --  u i f d )
		postpone swap		( u i f d -- u i d f )

		postpone if			( u i d f -- u i d )
			postpone -rot	( u i d -- d u i )
			postpone 2drop	( d u i -- d )
			postpone branch
		postpone then

		(loop-open)
	; immediate

\ https://forth-standard.org/standard/core/LOOP
\
\ Append the run-time semantics given below to the current definition. Resolve
\ the destination of all unresolved occurrences of LEAVE between the location
\ given by do-sys and the next location for a transfer of control, to execute
\ the words following the LOOP.
\
\ At runtime: An ambiguous condition exists if the loop control parameters are
\ unavailable. Add one to the loop index. If the loop index is then equal to the
\ loop limit, discard the loop parameters and continue execution immediately
\ following the loop. Otherwise continue execution at the beginning of the loop.

	: (loop) ( -- done? ) ( r: exit-dst u i ret )
		r-1@ 1+ dup			( -- i+1 1+1 ) ( r: exit-dst u i ret )
		r-1!				( i+1 i+1 -- ) ( r: exit-dst u i ret -- exit-dst u i+1 ret )
		r-2@ =				( i+1 -- done? ) \ i == u
	;

	: loop  ( C: dest -- )
		postpone (loop)		\ produces done?
  		(loop-close)
	; immediate

\ https://forth-standard.org/standard/core/PlusLOOP
\
\ Append the run-time semantics given below to the current definition. Resolve
\ the destination of all unresolved occurrences of LEAVE between the location
\ given by do-sys and the next location for a transfer of control, to execute
\ the words following +LOOP.
\
\ At runtime: An ambiguous condition exists if the loop control parameters are
\ unavailable. Add n to the loop index. If the loop index did not cross the
\ boundary between the loop limit minus one and the loop limit, continue
\ execution at the beginning of the loop. Otherwise, discard the current loop
\ control parameters and continue execution immediately following the loop.

	: (+loop) ( n -- done? ) ( r: u i ret )
		dup 0= if
			drop false				( n -- done? )
			exit
		then

		r-1@ r-2@ -				( n i l -- n d )			\ d = i - l
		over r-1@ +				( n d -- n d newi )			\ newi = n + i
		dup r-1!				( n d newi -- n d newi ) ( r: u i ret -- u newi ret )
		r-2@ -					( n d newi -- n d newt )	\ newt = newi - l
		rot						( n d newt -- d newt n )

		\ n <> 0
		0< if
			\ n < 0
			0<					( d newt -- d f1 ) 		\ newt < 0
			swap 0< 0=			( d f1 -- f1 f2 ) 		\ (d < 0) = 0; d >= 0
			and					\ done? = (newt < 0) AND (d >= 0)
		else
			\ n > 0
			0< 0=				( d newt -- d f1 ) 		\ (newt < 0) = 0; newt >= 0
			swap 0<				( d f1  -- f1 f2) 		\ d < 0
			and					\ done? = (newt >= 0) AND (d < 0)
		then
	;

	: +loop ( n -- ) ( C: dest -- )
		postpone (+loop)            \ produces done?
  		(loop-close)
	; immediate

\ https://forth-standard.org/standard/core/CASE
\ https://forth-standard.org/standard/core/ENDCASE
\ https://forth-standard.org/standard/core/OF
\ https://forth-standard.org/standard/core/ENDOF

	\ : ?exit postpone if postpone exit postpone then ; immediate
