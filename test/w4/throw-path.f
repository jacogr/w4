\ -------------------------------------------------------------
testing THROW path

\ 0 THROW is no-op through patched throw alias.
: throw-zero 0 throw 123 ;
T{ throw-zero -> 123 }T

\ The zero fast path must preserve return-stack data, with or without CATCH.
: throw-zero-r 456 >r 0 throw r> ;
T{ throw-zero-r -> 456 }T
T{ ' throw-zero-r catch -> 456 0 }T
