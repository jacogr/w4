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

	: (source-pop) ( -- fid ) ( s: ... fid -- ... )
		(source-count)					( -- count )

		\ check for underflow, -35 invalid block number
		dup 0= #-35 and throw			( count -- count )

		\ retrieve cell, decrement count
		dup (source-cell@)				( count -- count fid )
		swap 1-	(source-count!)			( count fid -- fid )
	;

\ manage the current fid, source & >in

	variable (source-curr-fid^)

	: (source-curr-fid) ( -- fid ) (source-curr-fid^) @ ;
	: (source-curr-fid!) ( fid -- ) (source-curr-fid^) ! ;

	\ set cource-id, source & in^
	: (source-global-set) ( fid -- )
		dup (source-curr-fid!)	( fid -- fid )
		dup (fid>ln-pos^)		( fid -- fid in^ )
		(>in^) !				( fid in^ -- fid )
		dup (fid>ln-iov^)		( fid -- fid source^ )
		(source^) !				( fid source^ -- fid )
		(source-id!)			( fid -- )
	;

	: (source-get-prev) ( -- f )
		(source-count) if
			(source-pop)		( -- fid )
			(source-global-set)	( fid -- )

			true				( -- f )
		else false then			( -- f )
	;

	: (source-set-next) ( fid -- )
		\ store current if set
		(source-curr-fid) ?dup if
			(source-push)			( fid curr -- fid )
		then

		(source-global-set)			( fid -- )
	;
