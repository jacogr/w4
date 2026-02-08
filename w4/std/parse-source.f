m4_require_w4(`std/control.f')
m4_require_w4(`std/constants.f')

\ source stack

	$20 constant (source-max#) \ 32 cells
	\ (source-max#) 1+ cells buffer: (source-stack^)

\ aligned with wasm

	$100 constant (sizeof-fid-in)	\ 256
	$400 constant (sizeof-fid-ln)	\ 1024

	: (new-mem-src) ( c-addr u -- fid )
		align here (sizeof-fid) allot	( c-addr u -- c-addr u a-addr )
		-rot							( c-addr u a-addr -- a-addr c-addr u )
		sp-2@ (fid>ln-len!)				( a-addr c-addr u -- a-addr c-addr )
		over (fid>ln-ptr!)				( a-addr c-addr -- a-addr )
	;

	: (new-file-src) ( c-addr u -- fid )
		\ allocate, set path + hash
		align here (sizeof-fid) allot	( c-addr u -- c-addr u a-addr )
		-rot strdup						( c-addr u a-addr -- a-addr c-addr' u' )
		sp-2@ (xt>str+len+hash!)		( a-addr c-addr u -- a-addr )

		\ set line buffer
		here (sizeof-fid-ln) 1+ allot	( a-addr -- a-addr here )
		over (fid>ln-ptr!)				( a-addr here -- a-addr )

		\ set input buffer
		here (sizeof-fid-in) 1+ allot	( a-addr -- a-addr here )
		over (fid>in-ptr!)				( a-addr here -- a-addr )

		\ set flags
		(flg-is-vis)					( a-addr -- a-addr flags )	\ flags = visible
		over (fid>flags!)				( a-addr flags -- fid )
	;

\ helpers to push/pop from stack

	: (source-count) ( -- u ) (source-stack^) @ ;
	: (source-count!) ( u -- ) (source-stack^) ! ;
	: (source-cell!) ( fid idx -- ) cells (source-stack^) + ! ;
	: (source-cell@) ( idx -- fid ) dup if cells (source-stack^) + @ then ;

	: (source-current) ( -- fid ) ( s: ... fid -- ... )
		(source-count)			( -- count )
		(source-cell@)			( count -- fid )
	;

	: (source-push) ( fid -- ) ( s: ... -- ... fid )
		(source-count) 1+					( fid -- fid count' )

		\ check for overflow, -35 invalid block number
		dup (source-max#) = #-35 and throw	( fid count -- fid count )
		dup (source-count!)					( fid count -- fid count )

		\ store cell
		(source-cell!)						( fid count -- )
	;

	: (source-pop) ( -- fid ) ( s: ... fid -- ... )
		(source-count)				( -- count )

		dup if						( count -- count|0 )
			\ decrement count, get top
			1- dup					( count -- count' count' )
			(source-count!)			( count count -- count )
			(source-cell@)			( count -- fid )
		then
	;

\ manage the current fid, source & >in

	\ set source-id, source & >in
	: (source-global-set) ( fid -- )
		dup (fid>ln-pos^) (>in^) !		( fid -- fid )
		dup (fid>ln-iov^) (source^) !	( fid -- fid )

		\ set the new source-id
		dup (fid>flags@) 0= if drop -1 then
		(source-id!)
	;

	: (source-set-prev) (source-pop) (source-global-set) ;
	: (source-set-next) dup (source-push) (source-global-set) ;
