require w4/std/compile.f
require w4/std/logic.f
require w4/std/stack.f

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
		(latest>tail) name>prev 	\ get placeholder address
		>cs							( c: -- orig )
	;

	: (resolve) ( a-addr -- )
		cs>						( c: orig -- )
		name>xt >body			\ load placeholder body
		(latest>tail) swap !	\ write tail location
	;

\ https://forth-standard.org/standard/tools/AHEAD

	: ahead  ( C: -- orig )
		(mark)
		postpone branch
	; immediate

\ https://forth-standard.org/standard/core/IF

	: if  ( C: -- orig )
		(mark)
		postpone ?branch
	; immediate

\ https://forth-standard.org/standard/core/THEN

	: then  ( C: orig -- )
		(resolve)
	; immediate

\ https://forth-standard.org/standard/core/ELSE

	: else ( c: orig1 -- orig2 )
		postpone ahead	( c: orig1 -- orig1 orig2 )
		cs-swap			( c: orig1 -- orig2 orig1 )
		postpone then	( c: orig2 orig1 -- orig2 )
	; immediate

\ https://forth-standard.org/standard/core/BEGIN

	: begin ( -- ) ( c: -- r-top )
		(latest>tail) >cs		( c:  -- r-top )
	; immediate

\ https://forth-standard.org/standard/core/UNTIL

	: until ( c: r-top -- ) ( test -- )
		cs> lit,
		postpone ?branch	( test -- )
	; immediate

\ https://forth-standard.org/standard/core/WHILE

	: while  ( C: dest -- orig dest )
		postpone if
		cs-swap		\ 1 cs-roll in canonical
	; immediate

\ https://forth-standard.org/standard/core/AGAIN

	: again  ( -- ) ( C: r-top -- )
		cs> lit,
		postpone branch	\ unconditional jump to r-top
	; immediate

\ https://forth-standard.org/standard/core/REPEAT

	: repeat  ( C: orig dest -- )
		postpone again
		postpone then
	; immediate

\ https://forth-standard.org/standard/core/I

	: i ( -- i ) ( r: u i ret ) r-1@ ;

\ https://forth-standard.org/standard/core/J

	: j ( -- j ) ( r: u' j u i ret ) r-3@ ;

\ https://forth-standard.org/standard/core/LEAVE

	: leave ( r: u i ret -- u i' ret )
		r-2@ 1- r-1!	\ i := u - 1
	;

\ https://forth-standard.org/standard/core/UNLOOP

	: unloop ( r: u i ret -- )
		r>			( -- ret ) ( r: u i ret -- u i )
		2r> 2drop	( ret -- ret ) ( r: u i -- )
		>r			( ret -- ) ( r: -- ret )
	;

\ https://forth-standard.org/standard/core/DO
\ Slide the u i loop values into the structure

	: (do) ( u i -- ) ( r: -- u i ret )
		r>			( u i -- u i ret ) ( r: ret -- )
		-rot		( u i ret -- ret u i ) ( r: -- )
		2>r			( ret u i -- ret ) ( r: -- u i )
		>r			( ret -- ) ( r: u i -- u i ret )
	;

	: (loop-open)
		postpone drop
		postpone (do)		\ runtime: set up loop frame
		postpone begin
	;

	: (loop-close)
		postpone until
		postpone unloop		\ run-time drop loop frame
		postpone then
	;

	: do    ( u i -- ) ( C: -- dest )
		(mark)				\ emits dest literal; pushes orig on CS
		(loop-open)
	; immediate

\ https://forth-standard.org/standard/core/qDO

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

	: (loop) ( -- done? )
		r-1@ 1+ dup r-1!	( r: u i ret )
		r-2@ =				\ i == u
	;

	: loop  ( C: dest -- )
		postpone (loop)		\ produces done?
  		(loop-close)
	; immediate

\ https://forth-standard.org/standard/core/PlusLOOP

	: (+loop) ( n -- done? )
		r-1@ over + dup r-1!	\ n newi
		r-2@					\ n newi u
		rot 0<					\ newi u flagNeg (0|-1)
		over <					\ newi u lt
		-rot <					\ flagNeg ge?
		select					\ crossed?
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

\ https://forth-standard.org/standard/core/qDUP

	: ?dup dup if dup then ;
