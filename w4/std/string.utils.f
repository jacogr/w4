require loops.f
require stack.f

\ convert a character to lowercase

	: >lower-ascii ( c -- c' ) dup 'A' 'Z' 1+ within if $20 or then ;

\ duplicate a string in lowercase

	: strdup-n-lower ( c-addr u -- c-addr2 u )
		\ len == 0?
		?dup 0= if drop 0 0 exit then

		swap over			( src len -- len src u )
		here swap			( len src u -- len src dst u )
		dup allot			( len src dst u -- len src dst u )

		begin
			dup 0<>				( len src dst u -- len src dst u f )
		while					( len src dst u f -- len src dst u )
			1- 2dup				( len src dst u -- len src dst u' u' u' )
			sp-4@ + c@			( len src dst u u u -- len src dst u u c )
			>lower-ascii		( len src dst u u c -- len src dst u u c' )
			swap sp-3@ + c!		( len src dst u u c -- len src dst u )
		repeat

		drop nip				( len src dst u -- len dst )
		swap					( len dst -- dst len )
	;

\ Compare two strings byte for byte until the specified length

	: strcmpn ( c-addr1 c-addr2 u -- f )
		true swap						( c-addr1 c-addr2 u -- c-addr1 c-addr2 f u )

		begin
			\ length != 0 & f == true
			?dup 0<> if					( c-addr1 c-addr2 f u -- c-addr1 c-addr2 f u )
				over					( c-addr1 c-addr2 f u -- c-addr1 c-addr2 f u f )
			else
				drop 0 0				( c-addr1 c-addr2 f -- c-addr1 c-addr2 0 0 0 )
			then
		while							( c-addr1 c-addr2 f u f -- c-addr1 c-addr2 f u )
			1-							( c-addr1 c-addr2 f u -- c-addr1 c-addr2 f u' )
			2dup						( c-addr1 c-addr2 f u -- c-addr1 c-addr2 f u u u )
			sp-5@ + c@ swap				( c-addr1 c-addr2 f u u u -- c-addr1 c-addr2 f u c1 u )
			sp-4@ + c@					( c-addr1 c-addr2 f u c1 u -- c-addr1 c-addr2 f u c1 c2 )

			\ f = c1 == c2
			=							( c-addr1 c-addr2 f u c1 c2 -- c-addr1 c-addr2 f u f' )
			sp-2!						( c-addr1 c-addr2 f u f' -- c-addr1 c-addr2 f' u )
		repeat

		\ cleanup
		drop 2nip 						( c-addr1 c-addr2 f u -- f )
	;

\ Non-standard, widely knowm used in substitute.

	: bounds ( addr len -- addr+len addr ) over + swap ;

\ Non-standard, widely known. Returns the tail starting at the first occurrence of c
\ if not found: returns c-addr+u 0

	: scan ( c-addr u c -- c-addr' u' )
		-rot						( c-addr u c -- c a-addr u )

		begin
			\ length != 0 & c_at <> c
			dup 0<> if				( c c-addr u -- c c-addr u )
				over c@ sp-3@ <>	( c c-addr u -- c c-addr u f )
			else false then			( c c-addr u -- c c-addr u 0 )
		while						( c c-addr u f -- c c-addr u )
			swap 1+ swap 1-			( c c-addr u -- c c-addr' u' )
		repeat

		rot	drop					( c c-addr u -- c-addr u )
	;

\ Non-standard, widely known. \Skips leading c's; returns tail starting at first non-c
\ if all are c: returns c-addr+u 0

	: skip ( c-addr u c -- c-addr' u' )
		-rot						( c-addr u c -- c a-addr u )

		begin
			\ length != 0 & c_at == c
			dup 0<> if				( c c-addr u -- c c-addr u )
				over c@ sp-3@ =		( c c-addr u -- c c-addr u f )
			else false then			( c c-addr u -- c c-addr u 0 )
		while						( c c-addr u f -- c c-addr u )
			swap 1+ swap 1-			( c c-addr u -- c c-addr' u' )
		repeat

		rot	drop					( c c-addr u -- c-addr u )
	;
