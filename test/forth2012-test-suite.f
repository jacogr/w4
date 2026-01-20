\
\ this duplicates the base
\
\	forth2012-test-suite/src/runtests.fth
\
\ allowing us to run it through our tester (with no changes to the core),
\ this has better error reporting than the original
\

1 (test-verbose) !

\ ANS Forth tests - run all tests

\ Adjust the file paths as appropriate to your system
\ Select the appropriate test harness, either the simple tester.fr
\ or the more complex ttester.fs

CR .( Running ANS Forth and Forth 2012 test programs, version 0.13.4) CR

S" forth2012-test-suite/src/prelimtest.fth" INCLUDED

\ skipped, base version of T{ .. }T included as standard
\ S" forth2012-test-suite/src/tester.fr" INCLUDED
\ S" forth2012-test-suite/src/ttester.fs" INCLUDED

S" forth2012-test-suite/src/core.fr" INCLUDED
S" forth2012-test-suite/src/coreplustest.fth" INCLUDED
S" forth2012-test-suite/src/utilities.fth" INCLUDED
S" forth2012-test-suite/src/errorreport.fth" INCLUDED
S" forth2012-test-suite/src/coreexttest.fth" INCLUDED
\ UNPLANNED S" forth2012-test-suite/src/blocktest.fth" INCLUDED
S" forth2012-test-suite/src/doubletest.fth" INCLUDED
\ TODO S" forth2012-test-suite/src/exceptiontest.fth" INCLUDED
\ UNPLANNED S" forth2012-test-suite/src/facilitytest.fth" INCLUDED
\ TODO S" forth2012-test-suite/src/filetest.fth" INCLUDED
\ TODO S" forth2012-test-suite/src/localstest.fth" INCLUDED
\ UNPLANNED S" forth2012-test-suite/src/memorytest.fth" INCLUDED
\ TODO S" forth2012-test-suite/src/toolstest.fth" INCLUDED
\ TODO S" forth2012-test-suite/src/searchordertest.fth" INCLUDED
\ S" forth2012-test-suite/src/stringtest.fth" INCLUDED
REPORT-ERRORS

CR .( Forth tests completed ) CR CR

