m4_require_w4(`std/control.f')
m4_require_w4(`std/constants.f')

\ source stack

	$20 constant (source-max#) \ 32 cells
	(source-max#) 1+ cells buffer: (source-stack^)

\ helpers to push/pop from stack

	: (source-count) ( -- u ) (source-stack^) @ ;
	: (source-count!) ( u -- ) (source-stack^) ! ;
	: (source-cell!) ( fid idx -- ) cells (source-stack^) + ! ;
	: (source-cell@) ( idx -- fid ) cells (source-stack^) + @ ;

	: (source-push) ( fid -- ) ( s: ... -- ... fid )
		(source-count) 1+					( fid -- fid count' )

		\ check for overflow, -35 invalid block number
		dup (source-max#) = #-35 and throw	( fid count -- fid count )
		dup (source-count!)					( fid count -- fid count )

		\ store cell
		(source-cell!)						( fid count -- )
	;

	: (source-get-at) ( count -- fid )
		?dup if					( count -- count )
			(source-cell@)		( count -- fid )
		else 0 then				( -- 0 )
	;

	: (source-current) ( -- fid ) ( s: ... fid -- ... )
		(source-count)			( -- count )
		(source-get-at)			( count -- fid )
	;

	: (source-pop) ( -- fid ) ( s: ... fid -- ... )
		(source-count)			( -- count )

		?dup if
			\ decrement count, get top
			1- dup					( count -- count' count' )
			(source-count!)			( count count -- count )
			(source-get-at)			( count -- fid )
		else 0 then					( -- fid )
	;

\ manage the current fid, source & >in

	\ set cource-id, source & in^
	: (source-global-set) ( fid -- )
		dup (fid>ln-pos^)		( fid -- fid in^ )
		(>in^) !				( fid in^ -- fid )
		dup (fid>ln-iov^)		( fid -- fid source^ )
		(source^) !				( fid source^ -- fid )
		(source-id!)			( fid -- )
	;

	: (source-get-prev) ( -- fid|0 )
		(source-pop)			( -- fid )
		dup (source-global-set)	( fid -- fid )
	;

	: (source-set-next) ( fid -- )
		dup (source-push)		( fid -- fid )
		(source-global-set)		( fid -- )
	;
