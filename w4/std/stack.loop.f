m4_require_w4(`std/compile.f')
m4_require_w4(`std/loops.f')
m4_require_w4(`std/stack.f')

\ https://forth-standard.org/standard/core/qDUP
\
\ Duplicate x if it is non-zero.

	: ?DUP dup if dup then ;

\ https://forth-standard.org/standard/core/ROLL
\
\ Remove u. Rotate u+1 items on the top of the stack. An ambiguous condition
\ exists if there are less than u+2 items on the stack before ROLL is executed.

	: ROLL ( x0 i*x u.i -- i*x x0 )
		?dup if
			swap >r		( ... i*x u.i -- ... u.i ) ( r: -- i*x )
			1- recurse	( ... u.i -- u.i' )
			r> swap		( ... u.i -- i*x u.i ) ( r: i*x -- )
		then
	;

\ https://forth-standard.org/standard/tools/CS-ROLL
\
\ Remove u. Rotate u+1 elements on top of the control-flow stack so that
\ origu | destu is on top of the control-flow stack. An ambiguous condition
\ exists if there are less than u+1 items, each of which shall be an orig or
\ dest, on the control-flow stack before CS-ROLL is executed.

	: CS-ROLL ( u.i -- )
		?dup if
			cs> >r		( c: i*x-1 i*x -- i*x-1 ) ( r: -- i*x )
			1- recurse	( u.i -- u.i' )
			r> >cs		( c: ... -- ... i*x ) ( r: i*x -- )
		then
	;

\ https://forth-standard.org/standard/tools/NRfrom
\
\ Retrieve the items previously stored by an invocation of N>R. n is the
\ number of items placed on the data stack. It is an ambiguous condition
\ if NR> is used with data not stored by N>R.

	: NR> \ -- xn .. x1 N ; R: x1 .. xn N --
		\ Pull N items and count off the return stack.
		r> r> swap >r dup

		begin
			DUP
		while
			r> r> swap >r -rot
			1-
		repeat

		drop
	;

\ https://forth-standard.org/standard/tools/NtoR
\
\ Remove n+1 items from the data stack and store them for later retrieval by
\ NR>. The return stack may be used to store the data. Until this data has bee
\  retrieved by NR>:
\
\	- this data will not be overwritten by a subsequent invocation of N>R and
\	= a program may not access data placed on the return stack before N>R

	: N>R \ xn .. x1 N -- ; R: -- x1 .. xn n
		\ Transfer N items and count to the return stack.
		dup                        \ xn .. x1 N N --

		begin
			dup
		while
			rot r> swap >r >r      \ xn .. N N -- ; R: .. x1 --
			1-                      \ xn .. N 'N -- ; R: .. x1 --
		repeat

		drop                       \ N -- ; R: x1 .. xn --
		r> swap >r >r
	;

