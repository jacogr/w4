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
		over (name>value!)		( here^ val -- here^ )
	;

\ Creates a lookup list (list + hashed headers)

	: (new-lookup) ( count -- a-addr )
		\ size > 31 (tiny) & power of 2
		dup $1f >					( count -- count f1 ) \ f1 = count > 31
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

	: (new-lookup-tiny) ( -- a-addr ) $10 (new-lookup) ; \ 16
	: (new-lookup-small) ( -- a-addr ) $100 (new-lookup) ; \ 256
	: (new-lookup-large) ( -- a-addr ) $800 (new-lookup) ; \ 2048

\ Appends an "xt" to a list

	: (list-append) ( a-addr xt -- nt )
		\ ensure it is actually a list
		over (list>flags@)		( a-addr xt -- a-addr xt flags )
		(flg-list)				( a-addr xt flags -- a-addr xt flags a-addr xt flags exp )
		= 0= #-50 and throw		\ ensure flags == expected

		\ new nt, set xt as nt value
		(new-nt)				( a-addr xt -- a-addr nt )

		\ get tail
		over (list>tail@)		( a-addr nt -- a-addr nt tail )
		2dup					( a-addr nt tail -- a-addr nt tail nt tail )

		\ tail exist?
		?dup if					( a-addr nt tail nt tail -- a-addr nt tail nt tail )
			\ tail>next = nt, nt>prev = tail
			(name>next!)		( a-addr nt tail nt tail -- a-addr nt tail )
			over				( a-addr nt tail -- a-addr nt tail nt )
			(name>prev!)		( a-addr nt tail nt -- a-addr nt )
		else 2drop then 		( a-addr nt tail nt -- a-addr nt )

		\ get head
		dup rot	dup				( a-addr nt -- nt nt a-addr a-addr )
		(list>head@)			( nt nt a-addr a-addr -- nt nt a-addr head )

		\ head exists?
		if						( nt nt a-addr head -- nt nt a-addr )
			\ (list>head@) = nt
			(list>head!)		( nt nt a-addr -- nt )
		else 2drop then			( nt nt a-addr -- nt )
	;

\ TODO: list "insert", aka place item before tail (useful for token lists where
\ the exit token always appears as the last item in the list)

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
			dup dup						( c-addr1 c-addr2 f u -- c-addr1 c-addr2 f u u u )
			sp-5@ + c@ swap				( c-addr1 c-addr2 f u u u -- c-addr1 c-addr2 f u c1 u )
			sp-4@ + c@					( c-addr1 c-addr2 f u c1 u -- c-addr1 c-addr2 f u c1 c2 )

			\ f = c1 == c2
			=							( c-addr1 c-addr2 f u c1 c2 -- c-addr1 c-addr2 f u f' )
			sp-2!						( c-addr1 c-addr2 f u f' -- c-addr1 c-addr2 f' u )
		repeat

		\ cleanup
		drop 2nip 						( c-addr1 c-addr2 f u -- f )
	;

\ Find an item in a lookup list based on hash, lentgh & string value

	: (lookup-find) ( list c-addr u hash -- a-addr|0 )
		\ move lookup values
		-rot 2>r 						( list c-addr u hash -- list hash ) ( r: -- c-addr u )

		\ get list index
		swap (list>owner@)				( list hash -- hash index )

		\ mask & buckets to bucket
		dup (lookup>buckets@)			( hash index -- hash index buckets )
		swap (lookup>mask@)				( hash index buckets -- hash buckets mask )
		sp-2@ and +						( hash buckets mask -- hash bucket )

		\ bring back string, get head
		2r> rot	@ 0						( hash bucket -- hash c-addr u a-addr 0 ) ( r: c-addr u -- )

		\ find in bucket
		begin
			\ not found & a-addr <> 0
			0= over 0<> and				( hash c-addr u a-addr f -- hash c-addr u a-addr f' )
		while							( hash c-addr u a-addr f -- hash c-addr u a-addr )
			\ get hashes
			dup (name>value@)			( hash c-addr u a-addr -- hash c-addr u a-addr xt )
			dup (xt>hash@)				( hash c-addr u a-addr xt -- hash c-addr u a-addr xt hash1 )

			\ hash1 == hash?
			sp-5@ = if					( hash c-addr u a-addr xt hash1 -- hash c-addr u a-addr xt )
				\ get string
				>string					( hash c-addr u a-addr xt -- hash c-addr u a-addr c-addr1 u1 )

				\ u1 == u?
				sp-3@ = if				( hash c-addr u a-addr c-addr1 u1 -- hash c-addr u a-addr c-addr1 )
					\ compare strings
					sp-3@				( hash c-addr u a-addr c-addr1 -- hash c-addr u a-addr c-addr1 c-addr2 )
					sp-3@ 				( hash c-addr u a-addr c-addr1 c-addr2 -- hash c-addr u a-addr c-addr1 c-addr2 u )
					strcmpn				( hash c-addr u a-addr c-addr1 c-addr2 u -- hash c-addr u a-addr f )
				else 0 and then			( hash c-addr u a-addr c-addr1 -- hash c-addr u a-addr 0 )
			else 0 and then 			( hash c-addr u a-addr xt -- hash c-addr u a-addr 0 )

			\ not found, move to next
			?dup 0= if					( hash c-addr u a-addr f -- hash c-addr u a-addr )
				(name>link@) 0			( hash c-addr u a-addr -- c-addr u a-addr' 0 )
			then
		until

		\ cleanup
		-rot 2drop						( hash c-addr u a-addr -- hash a-addr )
		nip								( hash a-addr -- a-addr )
	;
