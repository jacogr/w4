m4_require(<!std/compile.f!>)
m4_require(<!std/control.f!>)
m4_require(<!std/file.f!>)
m4_require(<!std/interpret.f!>)
m4_require(<!std/value.f!>)

\ https://forth-standard.org/standard/exception/CATCH
\ https://forth-standard.org/standard/implement#imp:exception:CATCH
\
\ Push an exception frame on the exception stack and then execute the
\ xecution token xt (as with EXECUTE) in such a way that control can be
\ transferred to a point just after CATCH if THROW is executed during
\ the execution of xt.
\
\ If the execution of xt completes normally (i.e., the exception frame
\ pushed by this CATCH is not popped by an execution of THROW) pop the
\ exception frame and return zero on top of the data stack, above whatever
\ stack items would have been returned by xt EXECUTE. Otherwise, the remainder
\ of the execution semantics are given by THROW.

	variable HANDLER
	variable (throw-active)
	variable (throw-value)
	variable (catch-sc)
	variable (catch-sid)
	variable (catch-in)
	variable (catch-sp)
	variable (rp-live)
	variable (catch-locals-last)
	$20 constant (catch-frames-max#)
	$6 constant (catch-frame-cells#) \ sp >in sid sc locals^ prev-handler
	(catch-frames-max#) (catch-frame-cells#) * cells buffer: (catch-frames^)
	variable (catch-frames#)

	\ Restore data stack depth from an address within stack storage.
	: SP! ( a-addr -- ) (ds^) - $2 rshift (ds^) ! ;

	\ Restore return stack depth from an address within return stack storage.
	: RP! ( a-addr -- ) (rs^) - $2 rshift 1+ (rs^) ! ;

	\ Pointer that maps to a no-op RP! restore (current top return item).
	: (rp-noop^) ( -- a-addr ) (rs^) dup @ 1- cells + ;
	: (rp-live-save) ( -- ) (rs^) dup @ cells + @ (rp-live) ! ;
	: (rp-live-restore) ( -- ) (rp-live) @ (rs^) dup @ cells + ! ;
	: (rp-restore^) ( a-addr -- ) (rp-live-save) rp! (rp-live-restore) ;

	: (catch-frame^) ( i -- a-addr )
		(catch-frame-cells#) * cells (catch-frames^) +
	;

	: (catch-frame-push) ( sp in sid sc locals^ prev-handler -- )
		(catch-frames#) @ dup 1+ (catch-frames#) !
		(catch-frame^) >r
		r@ $5 cells + !	\ prev-handler
		r@ $4 cells + !	\ locals^
		r@ $3 cells + !	\ source-count
		r@ $2 cells + !	\ source-id
		r@ $1 cells + !	\ >in
		r> !			\ sp
	;

	: (catch-frame-pop) ( -- )
		(catch-frames#) @ 1- dup (catch-frames#) !
		(catch-frame^) >r
		r@ $5 cells + @ handler !
		r@ $4 cells + @ (catch-locals-last) !
		r@ $3 cells + @ (catch-sc) !
		r@ $2 cells + @ (catch-sid) !
		r@ $1 cells + @ (catch-in) !
		r> @ (catch-sp) !
	;

	: (catch-restore-source) ( -- )
		begin
			(source-count) (catch-sc) @ >
		while
			(source-pop) drop
		repeat
		(catch-sc) @ if
			(catch-sc) @ (source-cell@) (source-global-set)
		else
			(catch-sid) @ (source-id!)
		then
		(catch-in) @ >in !
	;

	: (catch-apply-throw) ( -- exception# )
		(throw-value) @ (catch-sp) @ !
		(catch-sp) @ sp!
		(catch-locals-last) @ (locals-base^) !
		(catch-restore-source)
		$0 (throw-active) !
	;

	: CATCH ( xt -- exception# | 0 )	\ return addr on stack
		sp@ >in @ source-id (source-count)
		(locals-base^) @ handler @ (catch-frame-push)
		rp@ cell + handler !	( xt -- xt )	\ set current handler
		execute			( xt -- )		\ execute returns if no THROW
		(catch-frame-pop)
		(throw-active) @ if
			(catch-apply-throw)
		else
			$0
		then
	;

\ https://forth-standard.org/standard/core/QUIT
\ https://forth-standard.org/standard/implement#imp:core:QUIT
\
\ Empty the return stack, store zero in SOURCE-ID if it is present, make the
\ user input device the input source, and enter interpretation state. Do not
\ display a message. Repeat the following:
\
\ Accept a line from the input source into the input buffer, set >IN to zero,
\ and interpret. Display the implementation-defined system prompt if in
\ interpretation state, all processing has been completed, and no ambiguous
\ condition exists.

	: QUIT
		\ TODO empty the return stack and set the input source to the user input device
		postpone [
		begin
			refill
		while
			['] interpret catch

			\ handle catch
			case
				\ ok
				$0 of state @ 0= if ." OK" then cr endof
				\ abort
				$-1 of endof
				\ abort w/ message
				$-2 of endof
				\ exception
				dup ." Exception # " .
			endcase
		repeat
		bye
	;

\ https://forth-standard.org/standard/exception/THROW
\
\ If any bits of n are non-zero, pop the topmost exception frame from the
\ exception stack, along with everything on the return stack above that
\ frame. Then restore the input source specification in use before the
\ corresponding CATCH and adjust the depths of all stacks defined by this
\ standard so that they are the same as the depths saved in the exception
\ frame (i is the same number as the i in the input arguments to the
\ corresponding CATCH), put n on top of the data stack, and transfer control
\ to a point just after the CATCH that pushed that exception frame.
\
\ If the top of the stack is non zero and there is no exception frame on
\ the exception stack, the behavior is as follows:
\
\ If n is minus-one (-1), perform the function of 6.1.0670 ABORT (the version
\ of ABORT in the Core word set), displaying no message.
\
\ If n is minus-two, perform the function of 6.1.0680 ABORT" (the version of
\ ABORT" in the Core word set), displaying the characters ccc associated with the
\ ABORT" that generated the THROW.
\
\ Otherwise, the system may display an implementation-dependent message giving
\ information about the condition associated with the THROW code n. Subsequently,
\ the system shall perform the function of 6.1.0670 ABORT (the version of ABORT in
\ the Core word set).

	: (throw-capture-state) ( n f -- n f )
		\ update throw-value only when f=true; preserve on 0 THROW
		dup sp-2@ (throw-value) @
		select (throw-value) !			( n f f n old -- n f )

		\ throw-active <- throw-active OR f (never clear on 0 THROW)
		dup (throw-active) @ or
		dup (throw-active) !
		swap nip						( n f new -- n f )
	;

	: (throw-restore-rs) ( n f -- n f )
		\ restore return stack only when f=true, otherwise a no-op pointer
		dup (rp-noop^) handler @ swap
		select
		(rp-restore^)					( n f -- n f )
	;

	: (throw-pass-code) ( n f -- n|0 )
		\ pass 0 to native throw when f=true (handled by CATCH), else pass n
		$0 rot
		select
	;

	: (throw,patched) ( ??? exception# -- ??? exception# )
		dup 0<> handler @ 0<> and		( n -- n f )
		(throw-capture-state)			( n f -- n f )
		(throw-restore-rs)				( n f -- n f )
		(throw-pass-code)				( n f -- n|0 )
		(throw)
	; patch throw
