\ -------------------------------------------------------------
testing SP-n@

T{ 10 20 30 40 50 60 70 sp-0@ -> 10 20 30 40 50 60 70 70 }T
T{ 10 20 30 40 50 60 70 sp-1@ -> 10 20 30 40 50 60 70 60 }T
T{ 10 20 30 40 50 60 70 sp-2@ -> 10 20 30 40 50 60 70 50 }T
T{ 10 20 30 40 50 60 70 sp-3@ -> 10 20 30 40 50 60 70 40 }T
T{ 10 20 30 40 50 60 70 sp-4@ -> 10 20 30 40 50 60 70 30 }T
T{ 10 20 30 40 50 60 70 sp-5@ -> 10 20 30 40 50 60 70 20 }T
T{ 10 20 30 40 50 60 70 sp-6@ -> 10 20 30 40 50 60 70 10 }T

testing SP-n!

\ Index zero is the value being consumed by the store.
T{ 10 20 30 40 50 60 70 99 sp-0! -> 10 20 30 40 50 60 70 }T
T{ 10 20 30 40 50 60 70 99 sp-1! -> 10 20 30 40 50 60 99 }T
T{ 10 20 30 40 50 60 70 99 sp-2! -> 10 20 30 40 50 99 70 }T
T{ 10 20 30 40 50 60 70 99 sp-3! -> 10 20 30 40 99 60 70 }T
T{ 10 20 30 40 50 60 70 99 sp-4! -> 10 20 30 99 50 60 70 }T
T{ 10 20 30 40 50 60 70 99 sp-5! -> 10 20 99 40 50 60 70 }T
T{ 10 20 30 40 50 60 70 99 sp-6! -> 10 99 30 40 50 60 70 }T

\ Fill and drain the control stack without touching the caller's data.
: stack-cs-fill 10 >cs 20 >cs 30 >cs 40 >cs 50 >cs 60 >cs 70 >cs ;
: stack-cs-drain cs> cs> cs> cs> cs> cs> cs> ;
variable stack-cs-depth
cs-depth stack-cs-depth !
12345 >cs

testing CS-n@

T{ 123 stack-cs-fill cs-0@ stack-cs-drain -> 123 70 70 60 50 40 30 20 10 }T
T{ 123 stack-cs-fill cs-1@ stack-cs-drain -> 123 60 70 60 50 40 30 20 10 }T
T{ 123 stack-cs-fill cs-2@ stack-cs-drain -> 123 50 70 60 50 40 30 20 10 }T
T{ 123 stack-cs-fill cs-3@ stack-cs-drain -> 123 40 70 60 50 40 30 20 10 }T
T{ 123 stack-cs-fill cs-4@ stack-cs-drain -> 123 30 70 60 50 40 30 20 10 }T
T{ 123 stack-cs-fill cs-5@ stack-cs-drain -> 123 20 70 60 50 40 30 20 10 }T
T{ 123 stack-cs-fill cs-6@ stack-cs-drain -> 123 10 70 60 50 40 30 20 10 }T

testing CS-n!

T{ 123 stack-cs-fill 99 cs-0! stack-cs-drain -> 123 99 60 50 40 30 20 10 }T
T{ 123 stack-cs-fill 99 cs-1! stack-cs-drain -> 123 70 99 50 40 30 20 10 }T
T{ 123 stack-cs-fill 99 cs-2! stack-cs-drain -> 123 70 60 99 40 30 20 10 }T
T{ 123 stack-cs-fill 99 cs-3! stack-cs-drain -> 123 70 60 50 99 30 20 10 }T
T{ 123 stack-cs-fill 99 cs-4! stack-cs-drain -> 123 70 60 50 40 99 20 10 }T
T{ 123 stack-cs-fill 99 cs-5! stack-cs-drain -> 123 70 60 50 40 30 99 10 }T
T{ 123 stack-cs-fill 99 cs-6! stack-cs-drain -> 123 70 60 50 40 30 20 99 }T
T{ cs> -> 12345 }T
T{ cs-depth stack-cs-depth @ = -> true }T

\ Return-stack setup and cleanup stay in each test word so that no
\ helper call adds an extra return address above the values under test.

testing R-n@

: stack-r-fetch0 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r r-0@ r> r> r> r> r> r> r> ;
T{ 123 stack-r-fetch0 -> 123 70 70 60 50 40 30 20 10 }T
: stack-r-fetch1 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r r-1@ r> r> r> r> r> r> r> ;
T{ 123 stack-r-fetch1 -> 123 60 70 60 50 40 30 20 10 }T
: stack-r-fetch2 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r r-2@ r> r> r> r> r> r> r> ;
T{ 123 stack-r-fetch2 -> 123 50 70 60 50 40 30 20 10 }T
: stack-r-fetch3 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r r-3@ r> r> r> r> r> r> r> ;
T{ 123 stack-r-fetch3 -> 123 40 70 60 50 40 30 20 10 }T
: stack-r-fetch4 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r r-4@ r> r> r> r> r> r> r> ;
T{ 123 stack-r-fetch4 -> 123 30 70 60 50 40 30 20 10 }T
: stack-r-fetch5 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r r-5@ r> r> r> r> r> r> r> ;
T{ 123 stack-r-fetch5 -> 123 20 70 60 50 40 30 20 10 }T
: stack-r-fetch6 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r r-6@ r> r> r> r> r> r> r> ;
T{ 123 stack-r-fetch6 -> 123 10 70 60 50 40 30 20 10 }T

testing R-n!

: stack-r-store0 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r 99 r-0! r> r> r> r> r> r> r> ;
T{ 123 stack-r-store0 -> 123 99 60 50 40 30 20 10 }T
: stack-r-store1 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r 99 r-1! r> r> r> r> r> r> r> ;
T{ 123 stack-r-store1 -> 123 70 99 50 40 30 20 10 }T
: stack-r-store2 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r 99 r-2! r> r> r> r> r> r> r> ;
T{ 123 stack-r-store2 -> 123 70 60 99 40 30 20 10 }T
: stack-r-store3 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r 99 r-3! r> r> r> r> r> r> r> ;
T{ 123 stack-r-store3 -> 123 70 60 50 99 30 20 10 }T
: stack-r-store4 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r 99 r-4! r> r> r> r> r> r> r> ;
T{ 123 stack-r-store4 -> 123 70 60 50 40 99 20 10 }T
: stack-r-store5 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r 99 r-5! r> r> r> r> r> r> r> ;
T{ 123 stack-r-store5 -> 123 70 60 50 40 30 99 10 }T
: stack-r-store6 10 >r 20 >r 30 >r 40 >r 50 >r 60 >r 70 >r 99 r-6! r> r> r> r> r> r> r> ;
T{ 123 stack-r-store6 -> 123 70 60 50 40 30 20 99 }T
