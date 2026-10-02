\ Execution workloads: definitions are compiled once before timing.
decimal

: bench-step ( n -- n' ) 1+ ;

: bench-sum ( -- n )
	0 10000 0 do i + loop
;

: bench-calls ( -- n )
	0 10000 0 do bench-step loop
;

: bench-branches ( -- n )
	0 10000 0 do i 1 and if 1+ else 2 + then loop
;

variable bench-cell
: bench-memory ( -- n )
	0 bench-cell !
	10000 0 do 1 bench-cell +! loop
	bench-cell @
;
