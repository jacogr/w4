require parse.f
require text.f

\ Adapted from
\ https://github.com/gerryjackson/forth2012-test-suite/blob/387ca77a3586dcc5f366f8ac3ff707ab80a1e3df/src/tester.fr
\
\ (As included in the submodule test/forth2012-test-suite/src/tester.fr file)
\
\ From: John Hayes S1I
\ Subject: tester.fr
\ Date: Mon, 27 Nov 95 13:10:09 PST
\
\ (C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
\ MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.
\ VERSION 1.2

\ variables

	variable (test-num-errors)
	variable (test-is-error)
	variable (test-depth)
	variable (test-verbose)

	$20 cells buffer: (test-results)

\ alias for tester compat, point address into constant

	(test-num-errors) constant #ERRORS

\ empty the stack

	: (test-empty-stack) ( ... -- ) $0 (ds^) ! ;

\ display an error

	: (test-error) ( c-addr u -- )
		cr type source type
		base @ cr

		(test-depth) @ ?dup if
			dup decimal . hex ':' emit space
			dup 0 do				\ reverse results, keep size on top
				(test-results)
				i cells + @			( ... size --- ... size n )
				swap				( ... size n --- ... n size )
			loop
			0 do . loop				\ display all cells
		else
			." <empty stack>"
		then

		base !
		1 (test-is-error) !
		1 (test-num-errors) +!
		(test-empty-stack)
	;

\ start a test

	: T{ ( -- ) ;

\ record expected results

	: -> ( ... -- )
		depth dup (test-depth) !
		?dup if
			0 do
				(test-results)
				i cells + !
			loop
		then
	;

\ end test, compare expected vs actual

	: }T ( ... -- )
		depth (test-depth) @ = if
			depth ?dup if
				0 do
					(test-results) i cells + @
					<> if
						s" INCORRECT RESULT: " (test-error)
						leave
					then
				loop
			then
		else
			s" WRONG NUMBER OF RESULTS: " (test-error)
		then

		(test-is-error) @ 0= if
			'*' emit
		else
			0 (test-is-error) !
		then
	;

\ run tests (usefule for std test execution)

	: TESTING \ ( -- ) TALKING COMMENT.
		source (test-verbose) @
		if
			cr dup >r type cr r> >in !
		else
			>in ! drop '*' emit
		then
	;
