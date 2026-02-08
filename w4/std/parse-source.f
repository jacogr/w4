m4_require_w4(`std/control.f')
m4_require_w4(`std/constants.f')

\ source stack

	$20 constant (source-max#) \ 32 cells
	\ (source-max#) 1+ cells buffer: (source-stack^)

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
		(source-id!)					( fid -- )
	;

	: (source-set-prev) (source-pop) (source-global-set) ;
	: (source-set-next) dup (source-push) (source-global-set) ;
