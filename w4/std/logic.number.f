m4_require(`std/logic.f')
m4_require(`std/stack.f')

\ https://forth-standard.org/standard/core/WITHIN
\
\ Perform a comparison of a test value n1 | u1 with a lower limit n2 | u2 and
\ an upper limit n3 | u3, returning true if either (n2 | u2 < n3 | u3 and
\ (n2 | u2 <= n1 | u1 and n1 | u1 < n3 | u3)) or (n2 | u2 > n3 | u3 and
\ (n2 | u2 <= n1 | u1 or n1 | u1 < n3 | u3)) is true, returning false
\ otherwise. An ambiguous condition exists n1 | u1, n2 | u2, and n3 | u3 are
\ not all the same type.

	: WITHIN ( test low high -- flag ) over - >r - r> u< ;
