\ -------------------------------------------------------------
testing THROW path

\ 0 THROW is no-op through patched throw alias.
: throw-zero 0 throw 123 ;
T{ throw-zero -> 123 }T
