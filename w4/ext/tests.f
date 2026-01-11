decimal

T{ #1289       -> 1289        }T
\ T{ #12346789.  -> 12346789.   }T
T{ #-1289      -> -1289       }T
\ T{ #-12346789. -> -12346789.  }T
T{ $12eF       -> 4847        }T
\ T{ $12aBcDeF.  -> 313249263.  }T
T{ $-12eF      -> -4847       }T
\ T{ $-12AbCdEf. -> -313249263. }T
T{ %10010110   -> 150         }T
\ T{ %10010110.  -> 150.        }T
T{ %-10010110  -> -150        }T
\ T{ %-10010110. -> -150.       }T
T{ 'z'         -> 122         }T
T{ 1289       -> 1289        }T

hex

T{ #1289       -> #1289        }T
\ T{ #12346789.  -> 12346789.   }T
T{ #-1289      -> #-1289       }T
\ T{ #-12346789. -> -12346789.  }T
T{ 12eF       -> #4847        }T
\ T{ $12aBcDeF.  -> 313249263.  }T
T{ -12eF      -> #-4847       }T
\ T{ $-12AbCdEf. -> -313249263. }T
T{ %10010110   -> #150         }T
\ T{ %10010110.  -> 150.        }T
T{ %-10010110  -> #-150        }T
\ T{ %-10010110. -> -150.       }T

\ https://forth-standard.org/standard/testsuite
T{ -> }T                      ( Start with a clean slate )
( Test if any bits are set; Answer in base 1 )
T{ : BITSSET? if 0 0 else 0 then ; -> }T
T{  0 BITSSET? -> 0 }T        ( Zero is all bits clear )
T{  1 BITSSET? -> 0 0 }T      ( Other numbers have at least one bit )
T{ -1 BITSSET? -> 0 0 }T

\ https://forth-standard.org/standard/testsuite#test:core:CONSTANT
T{ 123 CONSTANT X123 -> }T
T{ X123 -> 123 }T
T{ : EQU CONSTANT ; -> }T
T{ X123 EQU Y123 -> }T
T{ Y123 -> 123 }T

\ defined to make the next tests pass (as per guidance in suite)
T{ 0 constant 0S -> }T
T{ -1 constant 1S -> }T

\ for comparisson tests
0 INVERT CONSTANT MAX-UINT
0 INVERT 1 RSHIFT CONSTANT MAX-INT
0 INVERT 1 RSHIFT INVERT CONSTANT MIN-INT
0 INVERT 1 RSHIFT CONSTANT MID-UINT
0 INVERT 1 RSHIFT INVERT CONSTANT MID-UINT+1

0S CONSTANT <FALSE>
1S CONSTANT <TRUE>

\ select
T{ <FALSE> a c select -> c }T
T{  <TRUE> a c select -> a }T

\ https://forth-standard.org/standard/testsuite#test:core:VARIABLE
T{ VARIABLE V1 ->     }T
T{    123 V1 ! ->     }T
T{        V1 @ -> 123 }T

\ https://forth-standard.org/standard/testsuite#test:core:INVERT
T{ 0S INVERT -> 1S }T
T{ 1S INVERT -> 0S }T

\ https://forth-standard.org/standard/core/ZeroEqual
T{        0 0= -> <TRUE>  }T
T{        1 0= -> <FALSE> }T
T{        2 0= -> <FALSE> }T
T{       -1 0= -> <FALSE> }T
T{ MAX-UINT 0= -> <FALSE> }T
T{ MIN-INT  0= -> <FALSE> }T
T{ MAX-INT  0= -> <FALSE> }T

\ https://forth-standard.org/standard/core/Zeroless
T{       0 0< -> <FALSE> }T
T{      -1 0< -> <TRUE>  }T
T{ MIN-INT 0< -> <TRUE>  }T
T{       1 0< -> <FALSE> }T
T{ MAX-INT 0< -> <FALSE> }T

\ https://forth-standard.org/standard/core/less
T{       0       1 < -> <TRUE>  }T
T{       1       2 < -> <TRUE>  }T
T{      -1       0 < -> <TRUE>  }T
T{      -1       1 < -> <TRUE>  }T
T{ MIN-INT       0 < -> <TRUE>  }T
T{ MIN-INT MAX-INT < -> <TRUE>  }T
T{       0 MAX-INT < -> <TRUE>  }T
T{       0       0 < -> <FALSE> }T
T{       1       1 < -> <FALSE> }T
T{       1       0 < -> <FALSE> }T
T{       2       1 < -> <FALSE> }T
T{       0      -1 < -> <FALSE> }T
T{       1      -1 < -> <FALSE> }T
T{       0 MIN-INT < -> <FALSE> }T
T{ MAX-INT MIN-INT < -> <FALSE> }T
T{ MAX-INT       0 < -> <FALSE> }T

\ https://forth-standard.org/standard/core/more
T{       0       1 > -> <FALSE> }T
T{       1       2 > -> <FALSE> }T
T{      -1       0 > -> <FALSE> }T
T{      -1       1 > -> <FALSE> }T
T{ MIN-INT       0 > -> <FALSE> }T
T{ MIN-INT MAX-INT > -> <FALSE> }T
T{       0 MAX-INT > -> <FALSE> }T
T{       0       0 > -> <FALSE> }T
T{       1       1 > -> <FALSE> }T
T{       1       0 > -> <TRUE>  }T
T{       2       1 > -> <TRUE>  }T
T{       0      -1 > -> <TRUE>  }T
T{       1      -1 > -> <TRUE>  }T
T{       0 MIN-INT > -> <TRUE>  }T
T{ MAX-INT MIN-INT > -> <TRUE>  }T
T{ MAX-INT       0 > -> <TRUE>  }T

\ https://forth-standard.org/standard/testsuite#test:core:AND
T{ 0 0 AND -> 0 }T
T{ 0 1 AND -> 0 }T
T{ 1 0 AND -> 0 }T
T{ 1 1 AND -> 1 }T
T{ 0 INVERT 1 AND -> 1 }T
T{ 1 INVERT 1 AND -> 0 }T

T{ 0S 0S AND -> 0S }T
T{ 0S 1S AND -> 0S }T
T{ 1S 0S AND -> 0S }T
T{ 1S 1S AND -> 1S }T

\ https://forth-standard.org/standard/testsuite#test:core:OR
T{ 0S 0S OR -> 0S }T
T{ 0S 1S OR -> 1S }T
T{ 1S 0S OR -> 1S }T
T{ 1S 1S OR -> 1S }T

\ https://forth-standard.org/standard/testsuite#test:core:XOR
T{ 0S 0S XOR -> 0S }T
T{ 0S 1S XOR -> 1S }T
T{ 1S 0S XOR -> 1S }T
T{ 1S 1S XOR -> 0S }T

\ https://forth-standard.org/standard/testsuite#test:core:RSHIFT
T{ MSB BITSSET? -> 0 0 }T
T{    1 0 RSHIFT -> 1 }T
T{    1 1 RSHIFT -> 0 }T
T{    2 1 RSHIFT -> 1 }T
T{    4 2 RSHIFT -> 1 }T
T{ 80000000 1F RSHIFT -> 1 }T                \ Biggest
T{  MSB 1 RSHIFT MSB AND ->   0 }T    \ RSHIFT zero fills MSBs
T{  MSB 1 RSHIFT     2*  -> MSB }T

\ https://forth-standard.org/standard/testsuite#test:core:LSHIFT
T{   1 0 LSHIFT ->    1 }T
T{   1 1 LSHIFT ->    2 }T
T{   1 2 LSHIFT ->    4 }T
T{   1 1F LSHIFT -> 80000000 }T      \ BIGGEST GUARANTEED SHIFT
T{  1S 1 LSHIFT 1 XOR -> 1S }T
T{ MSB 1 LSHIFT ->    0 }T

\ https://forth-standard.org/standard/core/NEGATE
T{  0 NEGATE ->  0 }T
T{  1 NEGATE -> -1 }T
T{ -1 NEGATE ->  1 }T
T{  2 NEGATE -> -2 }T
T{ -2 NEGATE ->  2 }T

\ https://forth-standard.org/standard/core/StoD
T{       0 S>D ->       0  0 }T
T{       1 S>D ->       1  0 }T
T{       2 S>D ->       2  0 }T
T{      -1 S>D ->      -1 -1 }T
T{      -2 S>D ->      -2 -1 }T
T{ MIN-INT S>D -> MIN-INT -1 }T
T{ MAX-INT S>D -> MAX-INT  0 }T

\ https://forth-standard.org/standard/core/UMTimes
T{ 0 0 UM* -> 0 0 }T
T{ 0 1 UM* -> 0 0 }T
T{ 1 0 UM* -> 0 0 }T
T{ 1 2 UM* -> 2 0 }T
T{ 2 1 UM* -> 2 0 }T
T{ 3 3 UM* -> 9 0 }T
T{ MID-UINT+1 1 RSHIFT 2 UM* ->  MID-UINT+1 0 }T
T{ MID-UINT+1          2 UM* ->           0 1 }T
T{ MID-UINT+1          4 UM* ->           0 2 }T
T{         1S          2 UM* -> 1S 1 LSHIFT 1 }T
T{   MAX-UINT   MAX-UINT UM* ->    1 1 INVERT }T

\ https://forth-standard.org/standard/core/MTimes
T{       0       0 M* ->       0 S>D }T
T{       0       1 M* ->       0 S>D }T
T{       1       0 M* ->       0 S>D }T
T{       1       2 M* ->       2 S>D }T
T{       2       1 M* ->       2 S>D }T
T{       3       3 M* ->       9 S>D }T
T{      -3       3 M* ->      -9 S>D }T
T{       3      -3 M* ->      -9 S>D }T
T{      -3      -3 M* ->       9 S>D }T
T{       0 MIN-INT M* ->       0 S>D }T
T{       1 MIN-INT M* -> MIN-INT S>D }T
T{       2 MIN-INT M* ->       0 1S  }T
T{       0 MAX-INT M* ->       0 S>D }T
T{       1 MAX-INT M* -> MAX-INT S>D }T
T{       2 MAX-INT M* -> MAX-INT     1 LSHIFT 0 }T
T{ MIN-INT MIN-INT M* ->       0 MSB 1 RSHIFT   }T
T{ MAX-INT MIN-INT M* ->     MSB MSB 2/         }T
T{ MAX-INT MAX-INT M* ->       1 MSB 2/ INVERT  }T

\ https://forth-standard.org/standard/core/Times
T{  0  0 * ->  0 }T          \ TEST IDENTITIE\S
T{  0  1 * ->  0 }T
T{  1  0 * ->  0 }T
T{  1  2 * ->  2 }T
T{  2  1 * ->  2 }T
T{  3  3 * ->  9 }T
T{ -3  3 * -> -9 }T
T{  3 -3 * -> -9 }T
T{ -3 -3 * ->  9 }T
T{ MID-UINT+1 1 RSHIFT 2 *               -> MID-UINT+1 }T
T{ MID-UINT+1 2 RSHIFT 4 *               -> MID-UINT+1 }T
T{ MID-UINT+1 1 RSHIFT MID-UINT+1 OR 2 * -> MID-UINT+1 }T

\ https://forth-standard.org/standard/testsuite#test:core:UM/MOD
T{        0            0        1 UM/MOD -> 0        0 }T
T{        1            0        1 UM/MOD -> 0        1 }T
T{        1            0        2 UM/MOD -> 1        0 }T
T{        3            0        2 UM/MOD -> 1        1 }T
T{ MAX-UINT        2 UM*        2 UM/MOD -> 0 MAX-UINT }T
T{ MAX-UINT        2 UM* MAX-UINT UM/MOD -> 0        2 }T
T{ MAX-UINT MAX-UINT UM* MAX-UINT UM/MOD -> 0 MAX-UINT }T

\ https://forth-standard.org/standard/core/SMDivREM
T{       0 S>D              1 SM/REM ->  0       0 }T
T{       1 S>D              1 SM/REM ->  0       1 }T
T{       2 S>D              1 SM/REM ->  0       2 }T
T{      -1 S>D              1 SM/REM ->  0      -1 }T
T{      -2 S>D              1 SM/REM ->  0      -2 }T
T{       0 S>D             -1 SM/REM ->  0       0 }T
T{       1 S>D             -1 SM/REM ->  0      -1 }T
T{       2 S>D             -1 SM/REM ->  0      -2 }T
T{      -1 S>D             -1 SM/REM ->  0       1 }T
T{      -2 S>D             -1 SM/REM ->  0       2 }T
T{       2 S>D              2 SM/REM ->  0       1 }T
T{      -1 S>D             -1 SM/REM ->  0       1 }T
T{      -2 S>D             -2 SM/REM ->  0       1 }T
T{       7 S>D              3 SM/REM ->  1       2 }T
T{       7 S>D             -3 SM/REM ->  1      -2 }T
T{      -7 S>D              3 SM/REM -> -1      -2 }T
T{      -7 S>D             -3 SM/REM -> -1       2 }T
T{ MAX-INT S>D              1 SM/REM ->  0 MAX-INT }T
T{ MIN-INT S>D              1 SM/REM ->  0 MIN-INT }T
T{ MAX-INT S>D        MAX-INT SM/REM ->  0       1 }T
T{ MIN-INT S>D        MIN-INT SM/REM ->  0       1 }T
T{      1S 1                4 SM/REM ->  3 MAX-INT }T
T{       2 MIN-INT M*       2 SM/REM ->  0 MIN-INT }T
T{       2 MIN-INT M* MIN-INT SM/REM ->  0       2 }T
T{       2 MAX-INT M*       2 SM/REM ->  0 MAX-INT }T
T{       2 MAX-INT M* MAX-INT SM/REM ->  0       2 }T
T{ MIN-INT MIN-INT M* MIN-INT SM/REM ->  0 MIN-INT }T
T{ MIN-INT MAX-INT M* MIN-INT SM/REM ->  0 MAX-INT }T
T{ MIN-INT MAX-INT M* MAX-INT SM/REM ->  0 MIN-INT }T
T{ MAX-INT MAX-INT M* MAX-INT SM/REM ->  0 MAX-INT }T

\ https://forth-standard.org/standard/core/FMDivMOD
T{       0 S>D              1 FM/MOD ->  0       0 }T
T{       1 S>D              1 FM/MOD ->  0       1 }T
T{       2 S>D              1 FM/MOD ->  0       2 }T
T{      -1 S>D              1 FM/MOD ->  0      -1 }T
T{      -2 S>D              1 FM/MOD ->  0      -2 }T
T{       0 S>D             -1 FM/MOD ->  0       0 }T
T{       1 S>D             -1 FM/MOD ->  0      -1 }T
T{       2 S>D             -1 FM/MOD ->  0      -2 }T
T{      -1 S>D             -1 FM/MOD ->  0       1 }T
T{      -2 S>D             -1 FM/MOD ->  0       2 }T
T{       2 S>D              2 FM/MOD ->  0       1 }T
T{      -1 S>D             -1 FM/MOD ->  0       1 }T
T{      -2 S>D             -2 FM/MOD ->  0       1 }T
T{       7 S>D              3 FM/MOD ->  1       2 }T
T{       7 S>D             -3 FM/MOD -> -2      -3 }T
T{      -7 S>D              3 FM/MOD ->  2      -3 }T
T{      -7 S>D             -3 FM/MOD -> -1       2 }T
T{ MAX-INT S>D              1 FM/MOD ->  0 MAX-INT }T
T{ MIN-INT S>D              1 FM/MOD ->  0 MIN-INT }T
T{ MAX-INT S>D        MAX-INT FM/MOD ->  0       1 }T
T{ MIN-INT S>D        MIN-INT FM/MOD ->  0       1 }T
T{    1S 1                  4 FM/MOD ->  3 MAX-INT }T
T{       1 MIN-INT M*       1 FM/MOD ->  0 MIN-INT }T
T{       1 MIN-INT M* MIN-INT FM/MOD ->  0       1 }T
T{       2 MIN-INT M*       2 FM/MOD ->  0 MIN-INT }T
T{       2 MIN-INT M* MIN-INT FM/MOD ->  0       2 }T
T{       1 MAX-INT M*       1 FM/MOD ->  0 MAX-INT }T
T{       1 MAX-INT M* MAX-INT FM/MOD ->  0       1 }T
T{       2 MAX-INT M*       2 FM/MOD ->  0 MAX-INT }T
T{       2 MAX-INT M* MAX-INT FM/MOD ->  0       2 }T
T{ MIN-INT MIN-INT M* MIN-INT FM/MOD ->  0 MIN-INT }T
T{ MIN-INT MAX-INT M* MIN-INT FM/MOD ->  0 MAX-INT }T
T{ MIN-INT MAX-INT M* MAX-INT FM/MOD ->  0 MIN-INT }T
T{ MAX-INT MAX-INT M* MAX-INT FM/MOD ->  0 MAX-INT }T

\ https://forth-standard.org/standard/testsuite#test:core:2*
T{   0S 2*       ->   0S }T
T{    1 2*       ->    2 }T
T{ 4000 2*       -> 8000 }T
T{   1S 2* 1 XOR ->   1S }T
T{  MSB 2*       ->   0S }T

\ https://forth-standard.org/standard/testsuite#test:core:2/
T{          0S 2/ ->   0S }T
T{           1 2/ ->    0 }T
T{        4000 2/ -> 2000 }T
T{          1S 2/ ->   1S }T \ MSB PROPOGATED
T{    1S 1 XOR 2/ ->   1S }T
T{ MSB 2/ MSB AND ->  MSB }T

\ https://forth-standard.org/standard/testsuite#test:core:0=
T{        0 0= -> <TRUE>  }T
T{        1 0= -> <FALSE> }T
T{        2 0= -> <FALSE> }T
T{       -1 0= -> <FALSE> }T
T{ MAX-UINT 0= -> <FALSE> }T
T{ MIN-INT  0= -> <FALSE> }T
T{ MAX-INT  0= -> <FALSE> }T

\ https://forth-standard.org/standard/testsuite#test:core:=
T{  0  0 = -> <TRUE>  }T
T{  1  1 = -> <TRUE>  }T
T{ -1 -1 = -> <TRUE>  }T
T{  1  0 = -> <FALSE> }T
T{ -1  0 = -> <FALSE> }T
T{  0  1 = -> <FALSE> }T
T{  0 -1 = -> <FALSE> }T

\ dup
T{ 12 dup -> 12 12 }T
T{ 12 34 56 2dup -> 12 34 56 34 56 }T

\ https://forth-standard.org/standard/core/TwoSWAP
T{ 1 2 3 4 2SWAP -> 3 4 1 2 }T

\ https://forth-standard.org/standard/testsuite#test:core:ROT
T{ 1 2 3 ROT -> 2 3 1 }T

\ https://forth-standard.org/standard/testsuite#test:core:DEPTH
T{ 0 1 DEPTH -> 0 1 2 }T
T{   0 DEPTH -> 0 1   }T
T{     DEPTH -> 0     }T

\ https://forth-standard.org/standard/core/Sq
T{ : GC4 S" XY" ; ->   }T
T{ GC4 SWAP DROP  -> 2 }T
T{ GC4 DROP DUP C@ SWAP CHAR+ C@ -> 58 59 }T
: GC5 S" A String"2DROP ; \ There is no space between the " and 2DROP
T{ GC5 -> }T

decimal
