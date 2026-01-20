\ Non-standard, but needed for this environment. Create a new list.

	: (new-list) ( -- a-addr )
		align here			( -- here^ )
		(sizeof-list) allot			\ allocate
		(flg-list) over >flags ! 	\ write flags
	;

\ Create a list entry with next/prev.

	: (new-nt) ( val -- a-addr )
		align here swap			( val -- here^ val )
		(sizeof-nt) allot		\ allocate
		over (flg-name)			( here^ val -- here^ val here^ flags )
		swap >flags ! 			( here^ val here^ flags -- here^ val )
		over >value !			( here^ val -- here^ )
	;

\ Appends and "xt" to a list

	: (list-append) ( a-addr xt -- nt )
		\ new nt, set xt as nt value
		(new-nt) swap	( a-addr xt -- a-addr nt xt )
		over >value !	( a-addr nt xt -- a-addr nt )

		\ TODO, in-progress
		\ - write nt to curr tail next
		\ - write curr tail and nt prev
		\ - update list head (if none)
		\ - update list tail to nt
	;
