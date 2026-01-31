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
