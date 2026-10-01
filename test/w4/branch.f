\ -------------------------------------------------------------
testing ?BRANCH

\ Branching normalizes any nonzero flag, including the sign bit alone.
: test-branch if 11 else 22 then ;
T{ 123 0 test-branch -> 123 22 }T
T{ 123 1 test-branch -> 123 11 }T
T{ 123 2 test-branch -> 123 11 }T
T{ 123 -1 test-branch -> 123 11 }T
T{ 123 $80000000 test-branch -> 123 11 }T
