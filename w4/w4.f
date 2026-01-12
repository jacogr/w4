
	<builds ] 1 $0150 ! 1 $0150 ! ;
	<builds : ] <builds ] ;

	: parse-name #32 parse ;
	: require parse-name required ;

require preamble.f

\
\ From here we should now be able to actually (mostly) parse
\ normal code, we have line comments and we have (inline) stack
\ comments so definitions can appear to be "normal"
\

\ https://forth-standard.org/standard/right-bracket
\
\	<builds ] ( -- )	\ define "]"
\		1 $0050 ! 		\ compile, 1 state ! (state constant not defined yet)
\		1 $0050 !		\ apply when executed
\	;

\ https://forth-standard.org/standard/core/Colon
\
\	<builds : ( -- )	\ define ":"
\		]				\ switch to compile
\		<builds	] 		\ apply "<builds ]" to children
\	;

\ https://forth-standard.org/standard/core/PARSE-NAME
\
\	: parse-name ( -- c-addr u ) #32 parse ;

\ https://forth-standard.org/standard/file/REQUIRE
\
\ 	: require ( i * x "name" -- j * x ) parse-name required ;

require std/compile.f
\ require w4/std/exceptions.f
require std/logic.f
require std/loops.f
require std/math.f
require std/memory.f
require std/parse.f
require std/stack.f
require std/test.f
require std/text.f

require ext/debug.f
\ require ext/hash.f

\
\ End of library
\
