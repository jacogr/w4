m4_require_w4(`std/compile.f')
m4_require_w4(`std/constants.f')
m4_require_w4(`std/logic-base.f')
m4_require_w4(`std/stack-base.f')
m4_require_w4(`std/stack-cs.f')
m4_require_w4(`std/stack-ptr.f')

\ Conditional branch when top of stack is 0
\ (Standard in older versions of ANS Forth, not in 2012)

	: ?BRANCH ( f dst -- ) ( r: ret -- ret|dst )
		swap 0<> swap	( f dst -- f' dst )	\ f' = f <> 0
		r@ swap			( f dst -- f retr dst ) ( r: ret )
		select			( f ret dst -- ret|dst )
		r!				( ret|dst -- ) ( r: ret -- ret|dst )
	;

\ (mark) returns the address of the last compiled literal cell (the one to patch).

	: (mark) ( c: -- orig )
		-1 lit,			\ placeholder
		(latest>prev^) 	\ get placeholder address
		>cs				( c: -- orig )
	;

\ (resolve) patches the literal cell created via (mark) to the current fallthrough address
\ on the control stack via (resolve-inner).

	: (resolve-inner) ( orig -- )
		(nt>value@) >value		( orig -- a-addr )
		(latest>tail^) swap !	\ write tail location
	;

	: (resolve) ( c: orig -- ) cs> (resolve-inner) ;

\ https://forth-standard.org/standard/tools/AHEAD
\
\ Put the location of a new unresolved forward reference orig onto the
\ control flow stack. Append the run-time semantics given below to the
\ current definition. The semantics are incomplete until orig is resolved
\ (e.g., by THEN).
\
\ At runtime: Continue execution at the location specified by the resolution of orig.

	: AHEAD  ( c: -- orig )
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

	: IF ( c: -- orig )
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

	: THEN ( c: orig -- )
		(resolve)
	; immediate

\ Non-standard, widely known alias for THEN (e.g. gforth, vfx)

	: ENDIF ( c: orig -- ) postpone then ; immediate

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

	: ELSE ( c: orig1 -- orig2 )
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

	: BEGIN ( -- ) ( c: -- r-top )
		(latest>tail^) >cs		( c:  -- r-top )
	; immediate

\ https://forth-standard.org/standard/core/UNTIL
\
\ Append the run-time semantics given below to the current definition,
\ resolving the backward reference dest.
\
\ At runtime: If all bits of x are zero, continue execution at the location
\ specified by dest.

	: UNTIL ( c: r-top -- ) ( test -- )
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

	: WHILE ( c: dest -- orig dest )
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

	: AGAIN ( -- ) ( c: r-top -- )
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

	: REPEAT  ( c: orig dest -- )
		postpone again
		postpone then
	; immediate

\ https://forth-standard.org/standard/core/I
\
\ n | u is a copy of the current (innermost) loop index. An ambiguous condition
\ exists if the loop control parameters are unavailable.

	: I ( -- i ) ( r: u i ret ) r-1@ ;

\ https://forth-standard.org/standard/core/J
\
\ n | u is a copy of the next-outer loop index. An ambiguous condition exists if
\ the loop control parameters of the next-outer loop, loop-sys1, are unavailable.

	: J ( -- j ) ( r: exit-j u' j exit-i u i ret ) r-4@ ;

\ https://forth-standard.org/standard/core/LEAVE
\
\ Discard the current loop control parameters. An ambiguous condition exists if
\ they are unavailable. Continue execution immediately following the innermost
\ syntactically enclosing DO...LOOP or DO...+LOOP.

	: LEAVE ( r: exit-dst u i ret -- exit-dst u i exit-dst )
		r-3@ r!		\ no branch, extra indirection breaks number of return items
	;

\ https://forth-standard.org/standard/core/UNLOOP
\
\ Discard the loop-control parameters for the current nesting level. An UNLOOP
\ is required for each nesting level before the definition may be EXITed. An
\ ambiguous condition exists if the loop-control parameters are unavailable.

	: UNLOOP ( r: exit-dst u i ret -- )
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
		>r swap r>	( u i exit-dst -- i u exit-dst ) ( r: ret -- ret )
		r> swap >r  ( i u exit-dst -- i u ret ) ( r: ret -- exit-dst )
		swap >r		( i u ret -- i ret ) ( r: exit-dst -- exit-dst u )
		swap >r		( i ret -- ret ) ( r: exit-dst u -- exit-dst u i )
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

	: DO ( u i -- ) ( c: -- dest )
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

	: ?DO ( u i -- ) ( c: -- orig dest )
		postpone 2dup		( u i -- u i u i )
		postpone =			( u i u i -- u i f )

		(mark)				( u i f --  u i f d )

		postpone swap		( u i f d -- u i d f )
		postpone if			( u i d f -- u i d )
			\ setup stack as "normal" do would, we are returning
			\ into unloop, so needs (a) valid exit-dst & (b) two
			\ more items (unused in unloop, but we have u & i)
			postpone >r		( u i d -- u i ) ( r: ret -- exit-dst )
			postpone 2>r	( u i -- ) ( r: exit-dst -- exit-dst u i )
			postpone leave
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
		r-1@ 1+ dup		( -- i+1 1+1 ) ( r: exit-dst u i ret )
		r-1!			( i+1 i+1 -- ) ( r: exit-dst u i ret -- exit-dst u i+1 ret )
		r-2@ =			( i+1 -- done? ) \ i == u
	;

	: LOOP ( c: dest -- )
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
			drop false			( n -- done? )
			exit
		then

		r-1@ r-2@ -				( n i u -- n d )			\ d = i - u
		swap dup				( n d -- d n n )
		r-1@ +					( d n n -- d n newi )		\ newi = n + i
		dup r-1!				( d n newi -- d n newi ) ( r: u i ret -- u newi ret )
		r-2@ -					( d n newi -- d n newt )	\ newt = newi - u
		swap					( d n newt -- d newt n )

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

	: +LOOP ( n -- ) ( c: dest -- )
		postpone (+loop)		\ produces done?
  		(loop-close)
	; immediate

\ https://forth-standard.org/standard/core/CASE
\
\ No interpretation semantics.
\
\  Mark the start of the CASE...OF...ENDOF...ENDCASE structure. Append the
\ run-time semantics given below to the current definition.
\
\ At runtime: Continue execution.

	: CASE ( c: -- 0 )
		0 >cs
	; immediate

\ https://forth-standard.org/standard/core/OF
\
\ No interpretation semantics.
\
\ Put of-sys onto the control flow stack. Append the run-time semantics given
\ below to the current definition. The semantics are incomplete until resolved
\ by a consumer of of-sys such as ENDOF.
\
\ At runtime: If the two values on the stack are not equal, discard the top
\ value and continue execution at the location specified by the consumer of
\ of-sys, e.g., following the next ENDOF. Otherwise, discard both values and
\ continue execution in line.

	: OF ( c: -- orig )
		postpone over	( sel x -- sel x sel )
		postpone =		( sel x sel -- sel flag )
		postpone if		\ IF consumes flag, leaves sel
		postpone drop	\ matched: drop sel
	; immediate

\ https://forth-standard.org/standard/core/ENDOF
\
\ No interpretation semantics.
\
\ Mark the end of the OF...ENDOF part of the CASE structure. The next location
\ for a transfer of control resolves the reference given by of-sys. Append the
\ run-time semantics given below to the current definition. Replace case-sys1
\ with case-sys2 on the control-flow stack, to be resolved by ENDCASE.
\
\ At runtime: Continue execution at the location specified by the consumer of case-sys2.

	: ENDOF    ( c: orig -- orig' )
		postpone else	\ resolves the IF, leaves a new orig for the forward branch
	; immediate

\ https://forth-standard.org/standard/core/ENDCASE
\
\ No interpretation semantics.
\
\ Mark the end of the CASE...OF...ENDOF...ENDCASE structure. Use case-sys to
\ resolve the entire structure. Append the run-time semantics given below to
\ the current definition.
\
\ At runtime: Discard the case selector x and continue execution.

	: ENDCASE ( c: 0 | orig... -- )
		postpone drop			\ no match path: drop sel

		begin
			cs> dup
		while
			(resolve-inner)		\ resolve each pending ELSE
		repeat

		drop
	; immediate
