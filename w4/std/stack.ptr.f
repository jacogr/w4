require logic.f

\ Returns the address of a specific stack pointer entry offset
\ from the topmost entry. Passing 1 would return the address of
\ the second-from-top entry on the stack. Same logic as above,
\ count is just offset by the index

	: (ds@@-) ( n -- a-addr )
		1+ negate		\ remove effect of count
		depth +			( -n -- c-n )
		cells (ds^) +	( c-n -- a-addr )
	;

	: SP-0@ ( -- ) #0 (ds@@-) @ ;
	: SP-0! ( -- ) #0 (ds@@-) ! ;

	: SP-1@ ( -- ) #1 (ds@@-) @ ;
	: SP-1! ( -- ) #1 (ds@@-) ! ;

	: SP-2@ ( -- ) #2 (ds@@-) @ ;
	: SP-2! ( -- ) #2 (ds@@-) ! ;

	: SP-3@ ( -- ) #3 (ds@@-) @ ;
	: SP-3! ( -- ) #3 (ds@@-) ! ;

	: SP-4@ ( -- ) #4 (ds@@-) @ ;
	: SP-4! ( -- ) #4 (ds@@-) ! ;

	: SP-5@ ( -- ) #5 (ds@@-) @ ;
	: SP-5! ( -- ) #5 (ds@@-) ! ;

	: SP-6@ ( -- ) #6 (ds@@-) @ ;
	: SP-6! ( -- ) #6 (ds@@-) ! ;

\ As per the above, a version for the control stack

	: CS-DEPTH ( r:... - u ) (cs^) @ ;

\ As per the (ds@@-) versions

	: (cs@-) ( n -- a-addr )
		cs-depth - negate
		cells (cs^) +
	;

	: CS@ ( -- ) cs-depth cells (cs^) + ;

	: CS-0@ ( -- ) #0 (cs@-) @ ;
	: CS-0! ( -- ) #0 (cs@-) ! ;

	: CS-1@ ( -- ) #1 (cs@-) @ ;
	: CS-1! ( -- ) #1 (cs@-) ! ;

	: CS-2@ ( -- ) #2 (cs@-) @ ;
	: CS-2! ( -- ) #2 (cs@-) ! ;

	: CS-3@ ( -- ) #3 (cs@-) @ ;
	: CS-3! ( -- ) #3 (cs@-) ! ;

	: CS-4@ ( -- ) #4 (cs@-) @ ;
	: CS-4! ( -- ) #4 (cs@-) ! ;

	: CS-5@ ( -- ) #5 (cs@-) @ ;
	: CS-5! ( -- ) #5 (cs@-) ! ;

	: CS-6@ ( -- ) #6 (cs@-) @ ;
	: CS-6! ( -- ) #6 (cs@-) ! ;

\ As per the above, a version for the return stack

	: R-DEPTH ( r:... - u ) (rs^) @	1- ; \ remove this return

\ As per the sp@ version, same style, this on return stack
\ (w/ additional cell removed for call into these)

	: RP@ ( -- a-addr ) r-depth 1- cells (rs^) + ; \ extra 1- for call to this

	: (rs@-) ( n -- a-addr )
		1+ negate
		r-depth +
		cells (rs^) +
	;

\ https://forth-standard.org/standard/core/RFetch

	: R@ ( -- x ) ( r: x -- x ) 1 (rs@-) @ ;

	: R! ( -- x ) ( x -- r:x ) 1 (rs@-) ! ;

	: R-0@ ( -- ) #1 (rs@-) @ ;
	: R-0! ( -- ) #1 (rs@-) ! ;

	: R-1@ ( -- ) #2 (rs@-) @ ;
	: R-1! ( -- ) #2 (rs@-) ! ;

	: R-2@ ( -- ) #3 (rs@-) @ ;
	: R-2! ( -- ) #3 (rs@-) ! ;

	: R-3@ ( -- ) #4 (rs@-) @ ;
	: R-3! ( -- ) #4 (rs@-) ! ;

	: R-4@ ( -- ) #5 (rs@-) @ ;
	: R-4! ( -- ) #5 (rs@-) ! ;

	: R-5@ ( -- ) #6 (rs@-) @ ;
	: R-5! ( -- ) #6 (rs@-) ! ;

	: R-6@ ( -- ) #7 (rs@-) @ ;
	: R-6! ( -- ) #7 (rs@-) ! ;
