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

\ Each scan commits >IN before the next token is parsed.
: parse-sequence-probe
	parse-name s" one" compare
	parse-name s" two" compare
	parse-name s" three" compare
	>in @ source nip =
;
T{ 123 s" parse-sequence-probe one   two three " evaluate -> 123 0 0 0 true }T

\ An offset past the source must remain unchanged and produce an empty token.
: parse-beyond-probe
	source nip #3 + >in !
	parse-name swap source drop - >in @ =
;
T{ 123 s" parse-beyond-probe" evaluate -> 123 0 true }T

: parse-max-offset-probe
	$ffffffff >in !
	parse-name swap source drop - >in @ =
;
T{ 123 s" parse-max-offset-probe" evaluate -> 123 0 true }T
