\ Non-standard, but needed for this environment. Create a new list.

	: (new-list) ( -- a-addr )
		align here						( -- here^ )
		(sizeof-list) allot				\ allocate
		(flg-list) over (list>flags!)	\ write flags
	;

\ Create a list entry with next/prev.

	: (new-nt) ( val -- a-addr )
		align here swap			( val -- here^ val )
		(sizeof-nt) allot		\ allocate
		over (flg-name)			( here^ val -- here^ val here^ flags )
		swap (name>flags!) 		( here^ val here^ flags -- here^ val )
		over (name>xt!)			( here^ val -- here^ )
	;

\ Appends an "xt" to a list

	: (list-append) ( a-addr xt -- nt )
		\ new nt, set xt as nt value
		(new-nt)			( a-addr xt -- a-addr nt )

		\ get tail
		over list>tail		( a-addr nt -- a-addr nt tail )
		2dup				( a-addr nt tail -- a-addr nt tail nt tail )

		\ tail exist? (tail>next = nt, nt>prev = tail)
		?dup if				( a-addr nt tail nt tail -- a-addr nt tail nt tail )
			(name>next!)	( a-addr nt tail nt tail -- a-addr nt tail )
			over			( a-addr nt tail -- a-addr nt tail nt )
			(name>prev!)	( a-addr nt tail nt -- a-addr nt )
		else 2drop then 	( a-addr nt tail nt -- a-addr nt )

		\ get head
		dup rot	dup			( a-addr nt -- nt nt a-addr a-addr )
		list>head			( nt nt a-addr a-addr -- nt nt a-addr head )

		\ head exists? (list>head = nt )
		if					( nt nt a-addr head -- nt nt a-addr )
			(list>head!)	( nt nt a-addr -- nt )
		else 2drop then		( nt nt a-addr -- nt )
	;
