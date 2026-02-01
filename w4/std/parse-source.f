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

	: (source-global-set) ( fid in -- )
		>in !				( fid in -- fid )
		dup (fid>source)	( fid -- fid source^ )
		(lniov^) !			( fid source^ -- fid )
		(source-id!)		( fid -- )
	;

	: (source-get-prev) ( -- f )
		(source-count) if
			(source-pop) dup		( -- fid fid )
			(source-curr-fid!)		( fid fid -- fid )

			\ setup >in & source
			dup (fid>in@)			( fid -- fid in )
			(source-global-set)		( fid in -- )

			true					( -- f )
		else false then				( -- f )
	;

	: (source-set-next) ( fid -- )
		\ store current if set
		(source-curr-fid) ?dup if
			>in 					( fid curr -- fid curr in )
			over (fid>in!)			( fid curr in -- fid curr )	\ >in into curr
			(source-push)			( fid curr -- fid )
		then

		\ set input as current
		dup (source-curr-fid!)		( fid -- fid )

		\ clear in, set source
		0 (source-global-set)		( fid -- )
	;
