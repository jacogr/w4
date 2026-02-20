m4_require(`std/constants.f')

\ Checks for the validity of the addresses, either valid, xt, nt or
\ list. In this the defined flags for the implemetation is used.

	: is-alloc-range? ( n -- f )
		here @ <	( n -- n<here )
	;

	: is-flag? ( n flag -- f ) swap over and = ;

	: is-flagged? ( a-addr flag -- f )
		swap 					( a-addr flag -- flag a-addr )
		dup is-alloc-range? if
			>flags @ 			( flag a-addr -- flag flags )
			swap is-flag?		( flags flag -- f )
		else drop 0 and then
	;

	: is-list? ( addr -- f ) (flg-list) is-flagged? ;

	: is-xt? ( addr -- f ) (flg-is-any) is-flagged? ;

	: is-nt? ( addr -- f )
		dup (flg-name) is-flagged? if
			(nt>value@) is-xt?
		else 0 and then
	;

\ Non-standard. Checks if 2 string regions has no overlap

	: is-overlapped? ( c-addr1 u c-addr2 u -- f )
		2over +
		sp-2@ u<

		if 4drop false exit then

		+ rot u< 0=
		nip
	;

\ checks if an nt is visible (via xt)

	: is-xt-visible? ( xt -- f ) >flags @ (flg-is-vis) is-flag? ;
