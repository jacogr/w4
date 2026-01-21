require constants.f
require loops.f
require stack.f

\ Non-standard, but needed for this environment. Create a new list.

	: ((new-list)) ( flags -- a-addr )
		align here swap			( flags -- here^ flags )
		(sizeof-list) allot		\ allocate
		(flg-list) or			( here^ flags -- here^ flags' )
		over (list>flags!)		( here^ flags' -- here^ )	\ write flags
	;

	: (new-list) ( -- a-addr ) 0 ((new-list)) ;

\ Create a list entry with next/prev.

	: (new-nt) ( val -- a-addr )
		align here swap			( val -- here^ val )
		(sizeof-nt) allot		\ allocate
		over (flg-name)			( here^ val -- here^ val here^ flags )
		swap (name>flags!) 		( here^ val here^ flags -- here^ val )
		over (name>value!)			( here^ val -- here^ )
	;

\ Creates a lookup list (list + hashed headers)

	: (new-lookup) ( count -- a-addr )
		\ size > 255 & power of 2
		dup $ff >					( count -- count f1 ) \ f1 = count > 255
		over dup					( count f1 -- count f1 count v )
		-1 and 0=					( count f1 count count -- count f1 f2 )		\ f2 = (count - 1) & count
		and							( count f1 f2 -- count f ) 					\ f = f1 & f2
		0= #-49 and throw			( count f -- count ) 						\ throw if not power of 2 & big enough

		\ allocate list (aligned) & buckets
		(flg-set-var) (new-list) 	( count flags -- count list )
		swap dup 1- >r 				( count list -- list count ) ( r: -- mask )	\ mask = count - 1
		here swap					( list count -- list buckets count )		\ buckets ptr
		cells allot					( list buckets count -- list buckets )		\ allocate count cells
		here swap					( list buckets -- list index buckets )		\ index ptr
		(sizeof-lookup) allot		\ allocate index

		\ setup index buckets & mask
		over (lookup>buckets!)		( list index buckets -- list index )		\ set buckets
		r> over (lookup>mask!)		( list index -- list index ) ( r: mask -- )	\ set mask

		\ set index on list
		over (list>owner!)			( list index -- )
	;

\ Appends an "xt" to a list

	: (list-append) ( a-addr xt -- nt )
		\ ensure it is actually a list
		over (list>flags@)		( a-addr xt -- a-addr xt flags )
		(flg-list)				( a-addr xt flags -- a-addr xt flags a-addr xt flags exp )
		= 0= #-50 and throw		\ ensure flags == expected

		\ new nt, set xt as nt value
		(new-nt)				( a-addr xt -- a-addr nt )

		\ get tail
		over (list>tail@)			( a-addr nt -- a-addr nt tail )
		2dup					( a-addr nt tail -- a-addr nt tail nt tail )

		\ tail exist? (tail>next = nt, nt>prev = tail)
		?dup if					( a-addr nt tail nt tail -- a-addr nt tail nt tail )
			(name>next!)		( a-addr nt tail nt tail -- a-addr nt tail )
			over				( a-addr nt tail -- a-addr nt tail nt )
			(name>prev!)		( a-addr nt tail nt -- a-addr nt )
		else 2drop then 		( a-addr nt tail nt -- a-addr nt )

		\ get head
		dup rot	dup				( a-addr nt -- nt nt a-addr a-addr )
		(list>head@)				( nt nt a-addr a-addr -- nt nt a-addr head )

		\ head exists? ((list>head@) = nt )
		if						( nt nt a-addr head -- nt nt a-addr )
			(list>head!)		( nt nt a-addr -- nt )
		else 2drop then			( nt nt a-addr -- nt )
	;

\ Appends an "xt" to a lookup. Here a-addr is the pointer to the list

	: (lookup-append) 				( a-addr xt -- nt )
		\ add the entry to the linked list
		over swap					( a-addr xt -- a-addr a-addr xt )
		(list-append)				( a-addr a-addr xt -- a-addr nt )

		\ get index from list
		swap (list>owner@)			( a-addr nt -- nt index )

		\ get mask offset & bucket pointer
		dup (lookup>mask@) 			( nt index -- nt index mask )
		sp-2@ and cells				( nt index mask -- nt index off )
		swap (lookup>buckets@) +	( nt index off -- nt bucket )

		\ current bucket head, store as link, update
		2dup @ swap					( nt bucket -- nt bucket head nt )
		(name>link!)				( nt bucket head nt -- nt bucket )	\ write link
		over swap !					( nt bucket -- nt )					\ write nt as head
	;
