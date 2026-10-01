\ -------------------------------------------------------------
testing SELECT

\ Preserve values below the operands and consume all three operands.
T{ 123 false 11 22 select -> 123 11 }T
T{ 123 true 11 22 select -> 123 22 }T
T{ false $80000000 $7fffffff select -> $80000000 }T
T{ true $80000000 $7fffffff select -> $7fffffff }T

\ SELECT also preserves its bitwise behavior for partial masks.
T{ $0f0f0f0f $aaaaaaaa $55555555 select -> $a5a5a5a5 }T
