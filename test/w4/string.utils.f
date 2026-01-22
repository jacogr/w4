\ -------------------------------------------------------------
testing streq-n

T{ s" abcdef" s" abcdef" streq-n -> TRUE }T
T{ s" abc" s" abcdef" streq-n -> FALSE }T
T{ s" abcdef" s" abc" streq-n -> FALSE }T
T{ s" abc" s" def" streq-n -> FALSE }T
T{ s" abcDEF" s" abcdef" streq-n -> FALSE }T

\ -------------------------------------------------------------
testing strcpy-n-lower

64 buffer: tbuf

T{ s" AbCDeF" tbuf swap strcpy-n-lower -> tbuf 6 }T
T{ tbuf 6 s" abcdef" streq-n -> TRUE }T

T{ s" 9-_Zz!" tbuf swap strcpy-n-lower -> tbuf 6 }T
T{ tbuf 6 s" 9-_zz!" streq-n -> TRUE }T

T{ $cc tbuf 6 + c!  $dd tbuf 7 + c! -> }T
T{ s" ABCDEF" tbuf swap strcpy-n-lower -> tbuf 6 }T
T{ tbuf 6 s" abcdef" streq-n -> TRUE }T
T{ tbuf 6 + c@ -> $cc }T
T{ tbuf 7 + c@ -> $dd }T


\ -------------------------------------------------------------
testing strdup-n-lower

T{ s" AbCDeF" strdup-n-lower nip -> 6 }T
T{ s" AbCDeF" strdup-n-lower s" abcdef" streq-n -> TRUE }T
T{ 0 0 strdup-n-lower -> 0 0 }T
