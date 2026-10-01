\ -------------------------------------------------------------
testing byte whitespace classification

\ Consume the rest of an evaluated source and report token length and
\ whether >IN reached the end, including any consumed delimiter.
: parse-byte-probe parse-name nip >in @ source nip = ;

\ Leading whitespace is skipped; bytes above 32 belong to the token.
T{ 123 s\" parse-byte-probe \x00x" evaluate -> 123 1 true }T
T{ s\" parse-byte-probe \x20x" evaluate -> 1 true }T
T{ s\" parse-byte-probe \x21x" evaluate -> 2 true }T
T{ s\" parse-byte-probe \x80x" evaluate -> 2 true }T
T{ s\" parse-byte-probe \xffx" evaluate -> 2 true }T

\ The same boundary terminates a token and advances past its delimiter.
T{ 123 s\" parse-byte-probe x\x00" evaluate -> 123 1 true }T
T{ s\" parse-byte-probe x\x20" evaluate -> 1 true }T
T{ s\" parse-byte-probe x\x21" evaluate -> 2 true }T
T{ s\" parse-byte-probe x\x80" evaluate -> 2 true }T
T{ s\" parse-byte-probe x\xff" evaluate -> 2 true }T

T{ s\" parse-byte-probe " evaluate -> 0 true }T
T{ s\" parse-byte-probe \x00\t\r\n " evaluate -> 0 true }T
