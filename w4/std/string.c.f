require loops.f
require stack.f

\ convert a character to lowercase

	: >lower-ascii ( c -- c' ) dup 'A' 'Z' 1+ within if $20 or then ;

\ dupliacet a string in lowercase

	: strdup-n-lower ( c-addr u -- c-addr2 u )
		swap over				( c-addr u -- len src u )
		here swap				( len src u -- len src dst u )
		allot					( len src dst u -- len src dst )
		sp-2@					( len src dst u -- len src dst u )

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
			dup 0<>						( c-addr1 c-addr2 f u -- c-addr1 c-addr2 f u f1 )
			sp-2@ true =				( c-addr1 c-addr2 f u f1 -- c-addr1 c-addr2 f u f1 f2 )
			and							( c-addr1 c-addr2 f u f1 f2 -- c-addr1 c-addr2 f u f' )
		while							( c-addr1 c-addr2 f u -- c-addr1 c-addr2 f u )
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
