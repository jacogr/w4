
\ layouts for xt, aligned with wasm

	\ 	str  : name pointer
	\	len  : name length
	\	hash :  hash for name
	\	flags: always at index 3
	\ 	value: flags-specific value
	: (sizeof-xt) ( -- u ) $5 cells ;

	: (xt>str!) ( c-addr xt -- ) ! ;
	: (xt>len!) ( c-addr xt -- ) $1 cells + ! ;

	: (xt>str+len@) ( xt -- c-addr u ) >str+len ;
	: (xt>str+len!) ( c-addr len xt -- )
		swap over	( c-addr len xt -- c-addr xt len xt )
		(xt>len!)	( c-addr xt len xt -- c-addr xt )
		(xt>str!)	( c-addr xt -- )
	;

	: (xt>hash@) ( a-addr -- u ) $2 cells + @ ;
	: (xt>hash!) ( u a-addr -- ) $2 cells + ! ;

	: (xt>flags@) ( a-addr -- u ) >flags @ ; \ $3 cells
	: (xt>flags!) ( u a-addr -- ) >flags ! ;

	: (xt>value@) ( a-addr -- u ) >value @ ; \ $4 cells
	: (xt>value!) ( u a-addr -- ) >value ! ;

\ layouts for names, aligned with wasm

	\	prev : prev in list
	\	next : next in list
	\ 	link : link (for lookups)
	\	flags: always at index 3
	\	value: xt (or specific to list type)
	: (sizeof-nt) ( -- u ) $5 cells ;

	: (nt>prev@) ( a-addr -- u ) @ ;
	: (nt>prev!) ( u a-addr -- ) ! ;

	: (nt>next@) ( a-addr -- u ) $1 cells + @ ;
	: (nt>next!) ( u a-addr -- ) $1 cells + ! ;

	: (nt>link@) ( a-addr -- u ) $2 cells + @ ;
	: (nt>link!) ( u a-addr -- ) $2 cells + ! ;

	: (nt>flags@) ( a-addr -- u ) >flags @ ;
	: (nt>flags!) ( u a-addr -- ) >flags ! ;

	: (nt>value@) ( a-addr -- u ) >value @ ;
	: (nt>value!) ( u a-addr -- ) >value ! ;

\ layouts for lists, aligned with wasm

	\ 	head  : head pointer
	\ 	tail  : tail pointer
	\ 	owner : parent
	\ 	flags : always at index 3
	\ 	file  : if present
	\ 	rowcol: if present
	: (sizeof-lst) ( -- u ) $6 cells ;

	: (lst>head@) ( a-addr -- u ) @ ;
	: (lst>head!) ( u a-addr -- ) ! ;

	: (lst>tail@) ( a-addr -- u ) $1 cells + @ ;
	: (lst>tail!) ( u a-addr -- ) $1 cells + ! ;

	: (lst>owner@) ( a-addr -- u ) $2 cells + @ ;
	: (lst>owner!) ( u a-addr -- ) $2 cells + ! ;

	: (lst>flags@) ( a-addr -- u ) >flags @ ;
	: (lst>flags!) ( u a-addr -- ) >flags ! ;

	: (lst>file@) ( a-addr -- u ) $4 cells + @ ;
	: (lst>file!) ( u a-addr -- ) $4 cells + ! ;

	: (lst>rowcol@) ( a-addr -- u ) $5 cells + @ ;
	: (lst>rowcol!) ( u a-addr -- ) $5 cells + ! ;

\ layouts for lookup indexes

	\ 	buckets: array of bucket pointers, 2^n
	\ 	mask   : 2^n - 1, mask for bucket lookup
	: (sizeof-idx) ( -- u ) $2 cells ;

	: (idx>buckets@) ( a-addr -- u ) @ ;
	: (idx>buckets!) ( u a-addr -- ) ! ;

	: (idx>mask@) ( a-addr -- u ) $1 cells + @ ;
	: (idx>mask!) ( u a-addr -- ) $1 cells + ! ;

\ layouts for fileid

	\ 	 path: path/code for the source (cell 0 & 1 layout shared with xt)
	\  	  len: path/code length for the source
	\	 hash: path hash (lookups)
	\ 	flags: 1 = file
	\ 	   fd: external file descriptor
	\	  buf: line buffer
	\	 nbuf: line buffer counter
	\	   in: stored >in
	\  rowcol: rows & cols read
	: (sizeof-fid) ( -- u ) $9 cells ;

	: (fid>path+len@) ( fid -- c-addr u ) (xt>str+len@) ;
	: (fid>path+len!) ( c-addr len fid -- ) (xt>str+len!) ;

	: (fid>hash@) ( a-addr -- u ) $2 cells + @ ;
	: (fid>hash!) ( u a-addr -- ) $2 cells + ! ;

	: (fid>flags@) ( a-addr -- u ) >flags @ ;
	: (fid>flags!) ( u a-addr -- ) >flags ! ;

	: (fid>fd^) ( fid -- a-addr ) $4 cells + ;
	: (fid>fd@) ( fid -- fd ) $4 cells + @ ;

	: (fid>source) ( fid -- a-addr ) $5 cells + ;
	: (fid>buf^) ( fid -- a-addr ) $5 cells + @ ;
	: (fid>buf^!) ( a-addr fid -- ) $5 cells + ! ;

	: (fid>nbuf^) ( fid -- u ) $6 cells + ;
	: (fid>nbuf@) ( fid -- u ) $6 cells + @ ;
	: (fid>nbuf!) ( u fid -- ) $6 cells + ! ;

	: (fid>in@) ( a-addr -- u ) $7 cells + @ ;
	: (fid>in!) ( u a-addr -- ) $7 cells + ! ;

	: (fid>rowcol@) ( fid -- u ) $8 cells + @ ;
	: (fid>rowcol!) ( u fid -- ) $8 cells + ! ;

\ latest

	: (latest>value) latest >value @ ;
	: (latest>head^) (latest>value) (lst>head@) ;
	: (latest>tail^) (latest>value) (lst>tail@) ;
	: (latest>prev^) (latest>tail^) (nt>prev@) ;
	: (latest>body^) (latest>head^) (nt>value@) >value ;
