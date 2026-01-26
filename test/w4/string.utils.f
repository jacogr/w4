
\ -------------------------------------------------------------
testing STREQ-ni

T{ s" abcdef" s" abcdef" streq-ni -> TRUE }T
T{ s" abcDEF" s" abcdef" streq-ni -> TRUE }T
T{ s" abc" s" abcdef" streq-ni -> FALSE }T
T{ s" abcdef" s" abc" streq-ni -> FALSE }T
T{ s" abc" s" def" streq-ni -> FALSE }T

\ -------------------------------------------------------------
testing STRCPY

64 buffer: tbuf

T{ s" AbCDeF" tbuf swap strcpy -> tbuf 6 }T
T{ tbuf 6 s" abcdef" streq-ni -> TRUE }T

T{ s" 9-_Zz!" tbuf swap strcpy -> tbuf 6 }T
T{ tbuf 6 s" 9-_zz!" streq-ni -> TRUE }T

T{ $cc tbuf 6 + c!  $dd tbuf 7 + c! -> }T
T{ s" ABCDEF" tbuf swap strcpy -> tbuf 6 }T
T{ tbuf 6 s" abcdef" streq-ni -> TRUE }T
T{ tbuf 6 + c@ -> $cc }T
T{ tbuf 7 + c@ -> $dd }T

\ -------------------------------------------------------------
testing STRDUP

T{ s" AbCDeF" strdup nip -> 6 }T
T{ s" AbCDeF" strdup s" abcdef" streq-ni -> TRUE }T
T{ 0 0 strdup -> 0 0 }T

\ -------------------------------------------------------------
testing SCAN

\ found case: "%def" length = 4
T{ s" abc%def" '%' scan nip -> 4 }T
\ found case: first char of returned tail is '%'
T{ s" abc%def" '%' scan drop c@ -> '%' }T
\ not found: length 0
T{ s" abcdef" '%' scan nip -> 0 }T

