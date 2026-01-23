require compile.f
require loops.f
require text.f

\ \ https://forth-standard.org/standard/exception/CATCH
\ \ https://forth-standard.org/standard/implement#imp:exception:CATCH

\ 	VARIABLE HANDLER 0 HANDLER !

\ 	: CATCH ( xt -- exception# | 0 )   \ return addr on stack
\ 		SP@ >R             ( xt )       \ save data stack pointer
\ 		HANDLER @ >R       ( xt )       \ and previous handler
\ 		RP@ HANDLER !      ( xt )       \ set current handler
\ 		EXECUTE            ( )          \ execute returns if no THROW
\ 		R> HANDLER !       ( )          \ restore previous handler
\ 		R> DROP            ( )          \ discard saved stack ptr
\ 		0                 ( 0 )        \ normal completion
\ 	;

\ \ https://forth-standard.org/standard/core/QUIT
\ \ https://forth-standard.org/standard/implement#imp:core:QUIT

\ 	: QUIT
\ 	( empty the return stack and set the input source to the user input device )
\ 		POSTPONE [
\ 		REFILL
\ 		WHILE
\ 			['] INTERPRET CATCH
\ 			CASE
\ 				0 OF STATE @ 0= IF ." OK" THEN CR ENDOF
\ 				-1 OF ( Aborted ) ENDOF
\ 				-2 OF ( display message from ABORT" ) ENDOF
\ 				( default ) DUP ." Exception # " .
\ 			ENDCASE
\ 		REPEAT
\ 		BYE
\ 	;

\ \ https://forth-standard.org/standard/exception/THROW

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

\ https://forth-standard.org/standard/core/ABORT
\
\ Empty the data stack and perform the function of QUIT, which includes
\ emptying the return stack, without displaying a message.

	: ABORT #-1 throw ;

\ https://forth-standard.org/standard/exception/ABORTq
\
\ Parse ccc delimited by a " (double-quote). Append the run-time semantics
\ given below to the current definition.
\
\ At runtime: Remove x1 from the stack. If any bit of x1 is not zero, perform
\ the function of -2 THROW, displaying ccc if there is no exception frame on
\ the exception stack.

	: ABORT" ( "ccc<quote>" -- )
		postpone if
			postpone s"
			postpone type
			$-2 lit,
			postpone throw
		postpone then
	; immediate
