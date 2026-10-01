\ -------------------------------------------------------------
testing (interpret-number-conv)

\ conversions
T{ s" 12345" (interpret-number-conv) -> 12345 1 }T
T{ s" #12345" (interpret-number-conv) -> #12345 1 }T
T{ s" $12345" (interpret-number-conv) -> $12345 1 }T
T{ s" #12345ab" (interpret-number-conv) -> 0 0 }T
T{ s" $12345ab" (interpret-number-conv) -> $12345ab 1 }T

\ negative
T{ s" #-12345" (interpret-number-conv) -> #-12345 1 }T
T{ s" $-12345" (interpret-number-conv) -> $-12345 1 }T
T{ s" -12345" (interpret-number-conv) -> -12345 1 }T

\ double
T{ s" 12345." (interpret-number-conv) -> 12345 -1 }T

\ -------------------------------------------------------------
testing (execute)

\ Raw execution must resume correctly for native words, literals and calls.
T{ #7 #8 ' + (execute) #9 -> #15 #9 }T
T{ #123 (flg-xt-lit) (new-xt) (execute) #9 -> #123 #9 }T
T{ #-7 (flg-xt-lit) (flg-is-var) or (new-xt) (execute) #9 -> #-7 #-1 #9 }T

: raw-execute-target #42 ;
: raw-execute-caller ['] raw-execute-target (execute) #9 ;
T{ raw-execute-caller -> #42 #9 }T
