require constants.f
require loops.f
require stack.f
require string.utils.f
require text.f

require ../ext/hash.f

\ Non-standard, but needed for this environment. Create a new list.

	: ((new-list)) ( flags -- a-addr )
		align here swap			( flags -- here^ flags )
		(sizeof-lst) allot		\ allocate
		(flg-list) or			( here^ flags -- here^ flags' )
		over (lst>flags!)		( here^ flags' -- here^ )	\ write flags
	;

	: (new-list) ( -- a-addr ) 0 ((new-list)) ;

\ Create a list entry with next/prev.

	: (new-nt) ( val -- a-addr )
		align here swap			( val -- here^ val )
		(sizeof-nt) allot		\ allocate
		over (flg-name)			( here^ val -- here^ val here^ flags )
		swap (nt>flags!) 		( here^ val here^ flags -- here^ val )
		over (nt>value!)		( here^ val -- here^ )
	;

\ Creates a lookup list (list + hashed headers)

	: (new-lookup) ( count -- a-addr )
		\ size > 255 (tiny) & power of 2
		dup $ff >					( count -- count f1 ) 						\ f1 = count > 255
		over dup					( count f1 -- count f1 count count )
		1- and 0=					( count f1 count count -- count f1 f2 )		\ f2 = (count - 1) & count
		and							( count f1 f2 -- count f ) 					\ f = f1 & f2
		0= #-49 and throw			( count f -- count ) 						\ throw if not power of 2 & big enough

		\ allocate list (aligned) & buckets
		(flg-set-var) ((new-list)) 	( count flags -- count list )
		swap dup 1- >r 				( count list -- list count ) ( r: -- mask )	\ mask = count - 1
		here swap					( list count -- list buckets count )
		cells allot					( list buckets count -- list buckets )		\ allocate count cells
		here swap					( list buckets -- list index buckets )		\ index ptr
		(sizeof-idx) allot		\ allocate index

		\ setup index buckets & mask
		over (idx>buckets!)		( list index buckets -- list index )		\ set buckets
		r> over (idx>mask!)		( list index -- list index ) ( r: mask -- )	\ set mask

		\ set index on list
		over (lst>owner!)			( list index -- list )
	;

	: (new-lookup-small) ( -- a-addr ) $100 (new-lookup) ; \ 256
	: (new-lookup-large) ( -- a-addr ) $800 (new-lookup) ; \ 2048

\ Appends an "xt" to a list

	: (list-append) ( a-addr xt -- nt )
		\ flags can have variants in the lower 8 bits, e.g.
		\ (flg-list) & (flg-set-var) for lookups, so compare with
		\ and then =
		over (lst>flags@)		( list xt -- list xt flags )
		(flg-list) and			( list xt flags -- list xt f1 )	\ f1 = flg-list & flags
		(flg-list) = 			( list xt f1 -- list xt f2 )	\ f2 = f1 == flg-list
		0= #-50 and throw		\ ensure list

		\ new nt, set xt as nt value
		(new-nt)				( list xt -- list nt )

		\ get tail
		over (lst>tail@)		( list nt -- list nt tail )
		2dup					( list nt tail -- list nt tail nt tail )

		\ tail exist?
		?dup if					( list nt tail nt tail -- list nt tail nt tail )
			\ tail>next = nt, nt>prev = tail
			(nt>next!)		( list nt tail nt tail -- list nt tail )
			over				( list nt tail -- list nt tail nt )
			(nt>prev!)		( list nt tail nt -- list nt )
		else 2drop then 		( list nt tail nt -- list nt )

		\ set tail
		2dup swap				( list nt -- list nt nt list )
		(lst>tail!)			( list nt nt list -- list nt )

		\ get head
		dup rot	dup				( list nt -- nt nt list list )
		(lst>head@)			( nt nt list list -- nt nt list head )

		\ unset head?
		0= if					( nt nt list head -- nt nt list )
			(lst>head!)		( nt nt list -- nt )
		else 2drop then			( nt nt list -- nt )
	;

\ TODO: list "insert", aka place item before tail (useful for token lists where
\ the exit token always appears as the last item in the list)

\ Appends an "xt" to a lookup. Here a-addr is the pointer to the list

	: (lookup-append) 				( a-addr xt -- nt )
		\ add the entry to the linked list
		over swap					( list xt -- list list xt )
		(list-append)				( list list xt -- list nt )

		\ get index from list
		swap (lst>owner@)			( list nt -- nt index )

		\ get mask offset & bucket pointer
		dup (idx>mask@) 			( nt index -- nt index mask )
		sp-2@ 						( nt index mask -- nt index mask nt )
		(nt>value@) (xt>hash@)		( nt index mask nt -- nt index mask hash )
		and cells					( nt index mask hash -- nt index off )
		swap (idx>buckets@) +		( nt index off -- nt bucket )

		\ current bucket head, store as link, update
		2dup @ swap					( nt bucket -- nt bucket head nt )
		(nt>link!)					( nt bucket head nt -- nt bucket )	\ write link
		over swap !					( nt bucket -- nt )					\ write nt as head
	;

\ Find an item in a lookup list based on hash, length & string value

	: (lookup-find) ( list c-addr u hash -- nt|0 )
		\ move lookup values
		-rot 2>r 					( list c-addr u hash -- list hash ) ( r: -- c-addr u )

		\ get list index
		swap (lst>owner@)			( list hash -- hash index )

		\ mask & buckets to bucket
		dup (idx>buckets@)			( hash index -- hash index buckets )
		swap (idx>mask@)			( hash index buckets -- hash buckets mask )
		sp-2@						( hash index buckets -- hash buckets mask hash )
		and cells +					( hash buckets mask hash -- hash bucket )

		\ bring back string, get head
		@ 2r> 						( hash bucket -- hash nt c-addr u ) ( r: c-addr u -- )
		rot	0						( hash nt c-addr u -- hash c-addr u nt 0 )

		\ find in bucket
		begin
			\ found == 0 & nt <> 0
			0= over 0<> and			( hash c-addr u nt f -- hash c-addr u nt f' )
		while						( hash c-addr u nt f -- hash c-addr u nt )
			\ get hashes
			dup (nt>value@)			( hash c-addr u nt -- hash c-addr u nt xt )
			dup (xt>hash@)			( hash c-addr u nt xt -- hash c-addr u nt xt hash1 )

			\ hash1 == hash?
			sp-5@ = if				( hash c-addr u nt xt hash1 -- hash c-addr u nt xt )
				\ get string
				>str+len			( hash c-addr u nt xt -- hash c-addr u nt c-addr1 u1 )

				\ move check c-addr u to front
				sp-4@ 				( hash c-addr u nt c-addr1 u1 -- hash c-addr u nt c-addr1 u1 c-addr )
				sp-4@ 				( hash c-addr u nt c-addr1 u1 c-addr -- hash c-addr u nt c-addr1 u1 c-addr u )
				streq-n				( hash c-addr u nt c-addr1 u1 c-addr u --  hash c-addr u nt f )
			else drop 0 then 		( hash c-addr u nt xt -- hash c-addr u nt 0 )

			\ not found, move to next
			?dup 0= if				( hash c-addr u nt f -- hash c-addr u nt )
				(nt>link@) 0		( hash c-addr u nt -- hash c-addr u nt' 0 )
			then
		repeat

		\ cleanup
		2nip nip					( hash c-addr u nt -- nt )
	;

\ Like lookup-find, however this version only takes the wid and
\ the string + length, calculating a lowercase hash

	string-max 1+ buffer: (lookup-tmp)

	: (lookup-search) ( c-addr u wid -- nt|0 )
		over string-max > #-18 and throw

		-rot						( src u wid -- wid src u )
		(lookup-tmp) swap			( wid src u -- wid src dst u )
		strcpy-n-lower				( wid src dst u -- wid dst u )
		2dup host::hash				( wid dst u -- wid dst u hash )
		(lookup-find)				( wid dst u hash -- nt|0 )
	;

	: (lookup-search-xt) ( c-addr u wid -- xt|0 ) (lookup-search) (nt>value@) ;
