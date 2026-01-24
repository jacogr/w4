require logic.f

\ Returns the address of a specific stack pointer entry offset
\ from the topmost entry. Passing 1 would return the address of
\ the second-from-top entry on the stack. Same logic as above,
\ count is just offset by the index

	: (ds^-n) ( n -- a-addr )
		1+ negate		\ remove effect of count
		depth +			( -n -- c-n )
		cells (ds^) +	( c-n -- a-addr )
	;

	: SP-0@ ( -- ) #0 (ds^-n) @ ;
	: SP-0! ( -- ) #0 (ds^-n) ! ;

	: SP-1@ ( -- ) #1 (ds^-n) @ ;
	: SP-1! ( -- ) #1 (ds^-n) ! ;

	: SP-2@ ( -- ) #2 (ds^-n) @ ;
	: SP-2! ( -- ) #2 (ds^-n) ! ;

	: SP-3@ ( -- ) #3 (ds^-n) @ ;
	: SP-3! ( -- ) #3 (ds^-n) ! ;

	: SP-4@ ( -- ) #4 (ds^-n) @ ;
	: SP-4! ( -- ) #4 (ds^-n) ! ;

	: SP-5@ ( -- ) #5 (ds^-n) @ ;
	: SP-5! ( -- ) #5 (ds^-n) ! ;

	: SP-6@ ( -- ) #6 (ds^-n) @ ;
	: SP-6! ( -- ) #6 (ds^-n) ! ;

\ As per the above, a version for the control stack

	: CS-DEPTH ( r:... - u ) (cs^) @ ;

\ As per the (ds^-n) versions

	: (cs^-n) ( n -- a-addr )
		cs-depth - negate
		cells (cs^) +
	;

	: CS@ ( -- ) cs-depth cells (cs^) + ;

	: CS-0@ ( -- ) #0 (cs^-n) @ ;
	: CS-0! ( -- ) #0 (cs^-n) ! ;

	: CS-1@ ( -- ) #1 (cs^-n) @ ;
	: CS-1! ( -- ) #1 (cs^-n) ! ;

	: CS-2@ ( -- ) #2 (cs^-n) @ ;
	: CS-2! ( -- ) #2 (cs^-n) ! ;

	: CS-3@ ( -- ) #3 (cs^-n) @ ;
	: CS-3! ( -- ) #3 (cs^-n) ! ;

	: CS-4@ ( -- ) #4 (cs^-n) @ ;
	: CS-4! ( -- ) #4 (cs^-n) ! ;

	: CS-5@ ( -- ) #5 (cs^-n) @ ;
	: CS-5! ( -- ) #5 (cs^-n) ! ;

	: CS-6@ ( -- ) #6 (cs^-n) @ ;
	: CS-6! ( -- ) #6 (cs^-n) ! ;

\ As per the above, a version for the return stack

	: R-DEPTH ( r:... - u ) (rs^) @	1- ; \ remove this return

\ As per the sp@ version, same style, this on return stack
\ (w/ additional cell removed for call into these)

	: RP@ ( -- a-addr ) r-depth 1- cells (rs^) + ; \ extra 1- for call to this

	: (rs^-n) ( n -- a-addr )
		1+ negate
		r-depth +
		cells (rs^) +
	;

\ https://forth-standard.org/standard/core/RFetch

	: R@ ( -- x ) ( r: x -- x ) 1 (rs^-n) @ ;

	: R! ( -- x ) ( x -- r:x ) 1 (rs^-n) ! ;

	: R-0@ ( -- ) #1 (rs^-n) @ ;
	: R-0! ( -- ) #1 (rs^-n) ! ;

	: R-1@ ( -- ) #2 (rs^-n) @ ;
	: R-1! ( -- ) #2 (rs^-n) ! ;

	: R-2@ ( -- ) #3 (rs^-n) @ ;
	: R-2! ( -- ) #3 (rs^-n) ! ;

	: R-3@ ( -- ) #4 (rs^-n) @ ;
	: R-3! ( -- ) #4 (rs^-n) ! ;

	: R-4@ ( -- ) #5 (rs^-n) @ ;
	: R-4! ( -- ) #5 (rs^-n) ! ;

	: R-5@ ( -- ) #6 (rs^-n) @ ;
	: R-5! ( -- ) #6 (rs^-n) ! ;

	: R-6@ ( -- ) #7 (rs^-n) @ ;
	: R-6! ( -- ) #7 (rs^-n) ! ;
