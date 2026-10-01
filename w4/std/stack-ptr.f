m4_require(<!std/constants.f!>)
m4_require(<!std/logic-base.f!>)

\ Returns the address of a specific stack pointer entry offset
\ from the topmost entry. Passing 1 would return the address of
\ the second-from-top entry on the stack. Same logic as above,
\ count is just offset by the index

	: (ds^-n) ( n -- a-addr )
		invert			\ -(n + 1), removing the effect of count
		depth +			( -n -- c-n )
		cells (ds^) +	( c-n -- a-addr )
	;

\ Fixed byte offsets throughout SP-n, CS-n, RP@ and R-n embed CELLS
\ (4 bytes per cell). Update them if the cell size changes. Keep the
\ indexed helpers for callers whose index is only known at runtime.

	: SP-0@ ( -- ) sp@ @ ;
	: SP-0! ( -- ) sp@ ! ;

	: SP-1@ ( -- ) sp@ #4 - @ ;
	: SP-1! ( -- ) sp@ #4 - ! ;

	: SP-2@ ( -- ) sp@ #8 - @ ;
	: SP-2! ( -- ) sp@ #8 - ! ;

	: SP-3@ ( -- ) sp@ #12 - @ ;
	: SP-3! ( -- ) sp@ #12 - ! ;

	: SP-4@ ( -- ) sp@ #16 - @ ;
	: SP-4! ( -- ) sp@ #16 - ! ;

	: SP-5@ ( -- ) sp@ #20 - @ ;
	: SP-5! ( -- ) sp@ #20 - ! ;

	: SP-6@ ( -- ) sp@ #24 - @ ;
	: SP-6! ( -- ) sp@ #24 - ! ;

\ As per the above, a version for the control stack

	: CS-DEPTH ( c: ... -- u ) (cs^) @ ;

\ As per the (ds^-n) versions

	: (cs^-n) ( n -- a-addr )
		cs-depth - negate
		cells (cs^) +
	;

	: CS@ ( -- ) cs-depth cells (cs^) + ;

	: CS-0@ ( -- ) cs@ @ ;
	: CS-0! ( -- ) cs@ ! ;

	: CS-1@ ( -- ) cs@ #4 - @ ;
	: CS-1! ( -- ) cs@ #4 - ! ;

	: CS-2@ ( -- ) cs@ #8 - @ ;
	: CS-2! ( -- ) cs@ #8 - ! ;

	: CS-3@ ( -- ) cs@ #12 - @ ;
	: CS-3! ( -- ) cs@ #12 - ! ;

	: CS-4@ ( -- ) cs@ #16 - @ ;
	: CS-4! ( -- ) cs@ #16 - ! ;

	: CS-5@ ( -- ) cs@ #20 - @ ;
	: CS-5! ( -- ) cs@ #20 - ! ;

	: CS-6@ ( -- ) cs@ #24 - @ ;
	: CS-6! ( -- ) cs@ #24 - ! ;

\ As per the above, a version for the return stack

	: R-DEPTH ( r: ... -- u ) (rs^) @ 1- ; \ remove this return

\ Like SP@, return the caller's top cell, excluding RP@'s own return address.

	: RP@ ( -- a-addr ) (rs^) @ cells (rs^) + #4 - ;

	: (rs^-n) ( n -- a-addr )
		invert			\ -(n + 1), including the call offset
		r-depth +
		cells (rs^) +
	;

\ https://forth-standard.org/standard/core/RFetch

\ RP@ includes this helper's return address, so skip one extra cell.

	: R-0@ ( -- x ) rp@ #4 - @ ;
	: R-0! ( -- s ) rp@ #4 - ! ;

	: R-1@ ( -- x ) rp@ #8 - @ ;
	: R-1! ( -- x ) rp@ #8 - ! ;

	: R-2@ ( -- x ) rp@ #12 - @ ;
	: R-2! ( -- x ) rp@ #12 - ! ;

	: R-3@ ( -- x ) rp@ #16 - @ ;
	: R-3! ( -- x ) rp@ #16 - ! ;

	: R-4@ ( -- x ) rp@ #20 - @ ;
	: R-4! ( -- x ) rp@ #20 - ! ;

	: R-5@ ( -- x ) rp@ #24 - @ ;
	: R-5! ( -- x ) rp@ #24 - ! ;

	: R-6@ ( -- x ) rp@ #28 - @ ;
	: R-6! ( -- x ) rp@ #28 - ! ;

\ Direct access avoids the R-1@/R-1! wrapper frame. Skip only this word's
\ return address, using the same embedded one-cell offset as R-0@/R-0!.

	: R@ ( -- x ) rp@ #4 - @ ;
	: R! ( x -- ) rp@ #4 - ! ;
