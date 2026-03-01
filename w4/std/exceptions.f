m4_require(<!std/compile.f!>)
m4_require(<!std/control.f!>)
m4_require(<!std/file.f!>)
m4_require(<!std/interpret.f!>)

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

	: CATCH ( xt -- exception# | 0 )	\ return addr on stack
		sp@ >r			( xt -- xt )	\ save data stack pointer
		handler @ >r	( xt -- xt )	\ and previous handler
		rp@ handler !	( xt -- xt )	\ set current handler
		execute			( xt -- )		\ execute returns if no THROW
		r> handler !	( -- )			\ restore previous handler
		r> drop			( -- )			\ discard saved stack ptr
		$0				( -- 0 )		\ normal completion
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

\ 	: THROW ( ??? exception# -- ??? exception# )
\ 		?DUP IF          ( exc# )     \ 0 THROW is no-op
\ 			HANDLER @ RP!   ( exc# )     \ restore prev return stack
\ 			R> HANDLER !    ( exc# )     \ restore prev handler
\ 			R> SWAP >R      ( saved-sp ) \ exc# on return stack
\ 			SP! DROP R>     ( exc# )     \ restore stack
\ 			\ Return to the caller of CATCH because return
\ 			\ stack is restored to the state that existed
\ 			\ when CATCH began execution
\ 		THEN
\ 	;
