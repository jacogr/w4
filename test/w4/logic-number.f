\ -------------------------------------------------------------
testing comparison sign correction

\ Opposite signs, including differences that overflow a signed cell.
T{ 123 $80000000 $7fffffff < -> 123 true }T
T{ 123 $7fffffff $80000000 < -> 123 false }T
T{ $7fffffff $ffffffff < -> false }T
T{ $ffffffff $7fffffff < -> true }T
T{ $aaaaaaaa $55555555 < -> true }T
T{ $55555555 $aaaaaaaa < -> false }T

\ Same-sign subtraction and equality must return canonical flags.
T{ $80000000 $ffffffff < -> true }T
T{ $ffffffff $80000000 < -> false }T
T{ $40000000 $7fffffff < -> true }T
T{ $7fffffff $40000000 < -> false }T
T{ $80000000 $80000000 < -> false }T
T{ $7fffffff $7fffffff < -> false }T

\ Unsigned order across the sign boundary, with canonical flags.
T{ $80000000 $7fffffff u< -> false }T
T{ $7fffffff $80000000 u< -> true }T
T{ 123 $0 $ffffffff u< -> 123 true }T
T{ 123 $ffffffff $0 u< -> 123 false }T
T{ $0 $80000000 u< -> true }T
T{ $80000000 $0 u< -> false }T
T{ $aaaaaaaa $55555555 u< -> false }T
T{ $55555555 $aaaaaaaa u< -> true }T

\ Same high bits and equality.
T{ $80000000 $ffffffff u< -> true }T
T{ $ffffffff $80000000 u< -> false }T
T{ $0 $1 u< -> true }T
T{ $1 $0 u< -> false }T
T{ $0 $0 u< -> false }T
T{ $7fffffff $7fffffff u< -> false }T
T{ $80000000 $80000000 u< -> false }T
T{ $ffffffff $ffffffff u< -> false }T
