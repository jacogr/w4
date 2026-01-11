\ Returns the address of a specific stack pointer entry offset
\ from the topmost entry. Passing 1 would return the address of
\ the second-from-top entry on the stack. Same logic as above,
\ count is just offset by the index

	: (sp@-) ( n -- a-addr )
		1+ negate		\ remove effect of count
		depth +			( -n -- c-n )
		cells (sp^) +	( c-n -- a-addr )
	;

	: sp-1@ ( -- ) #1 (sp@-) @ ;
	: sp-1! ( -- ) #1 (sp@-) ! ;
	: sp-2@ ( -- ) #2 (sp@-) @ ;
	: sp-2! ( -- ) #2 (sp@-) ! ;
	: sp-3@ ( -- ) #3 (sp@-) @ ;
	: sp-3! ( -- ) #3 (sp@-) ! ;
	: sp-4@ ( -- ) #4 (sp@-) @ ;
	: sp-4! ( -- ) #4 (sp@-) ! ;
	: sp-5@ ( -- ) #5 (sp@-) @ ;
	: sp-5! ( -- ) #5 (sp@-) ! ;
	: sp-6@ ( -- ) #6 (sp@-) @ ;
	: sp-6! ( -- ) #6 (sp@-) ! ;

\ As per the above, a version for the control stack

	: cs-depth ( r:... - u ) (cp^) @ ;

\ As per the (sp@-) versions

	: (cs@-) ( n -- a-addr )
		cs-depth - negate
		cells (cp^) +
	;

	: cs@ ( -- ) cs-depth cells (cp^) + ;

	: cs-0@ ( -- ) #0 (cs@-) @ ;
	: cs-0! ( -- ) #0 (cs@-) ! ;
	: cs-1@ ( -- ) #1 (cs@-) @ ;
	: cs-1! ( -- ) #1 (cs@-) ! ;
	: cs-2@ ( -- ) #2 (cs@-) @ ;
	: cs-2! ( -- ) #2 (cs@-) ! ;
	: cs-3@ ( -- ) #3 (cs@-) @ ;
	: cs-3! ( -- ) #3 (cs@-) ! ;
	: cs-4@ ( -- ) #4 (cs@-) @ ;
	: cs-4! ( -- ) #4 (cs@-) ! ;

\ As per the above, a version for the return stack

	: r-depth ( r:... - u ) (rp^) @	1- ; \ remove this return

\ As per the sp@ version, same style, this on return stack
\ (w/ additional cell removed for call into these)

	: rp@ ( -- a-addr ) r-depth 1- cells (rp^) + ; \ extra 1- for call to this

	: (rp@-) ( n -- a-addr )
		1+ negate
		r-depth +
		cells (rp^) +
	;

\ https://forth-standard.org/standard/core/RFetch

	: r@ ( -- x ) ( r: x -- x ) 1 (rp@-) @ ;

	: r! ( -- x ) ( x -- r:x ) 1 (rp@-) !	;

	: r-1@ ( -- ) #2 (rp@-) @ ;
	: r-1! ( -- ) #2 (rp@-) ! ;
	: r-2@ ( -- ) #3 (rp@-) @ ;
	: r-2! ( -- ) #3 (rp@-) ! ;
	: r-3@ ( -- ) #4 (rp@-) @ ;
	: r-3! ( -- ) #4 (rp@-) ! ;
	: r-4@ ( -- ) #5 (rp@-) @ ;
	: r-4! ( -- ) #5 (rp@-) ! ;
