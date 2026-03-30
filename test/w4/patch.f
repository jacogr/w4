
\ -------------------------------------------------------------
testing PATCH

: foo 123 ;
: bar foo ;

T{ ' foo execute -> 123 }T
T{ bar -> 123 }T

: (foo,patched) 456 ; patch foo

T{ ' foo execute -> 456 }T
T{ bar -> 456 }T
