
	<builds ] 1 $0150 ! 1 $0150 ! ;
	<builds : ] <builds ] ;

	: parse-name #32 parse ;
	: require parse-name required ;

require w4/std/preamble.f

\
\ From here we should now be able to actually (mostly) parse
\ normal code, we have line comments and we have (inline) stack
\ comments so definitions can appear to be "normal"
\

\ https://forth-standard.org/standard/right-bracket
\
\	<builds ] ( -- )	\ define "]"
\		1 $0050 ! 		\ compile, 1 state ! (state constant not defined yet)
\		1 $0050 !		\ apply to children
\	;

\ https://forth-standard.org/standard/core/Colon
\
\	<builds : ( -- )	\ define ":"
\		]				\ compile
\		<builds	] 		\ apply "<builds [" to children
\	;

\ https://forth-standard.org/standard/core/PARSE-NAME
\
\	: parse-name ( -- c-addr u ) #32 parse ;

\ https://forth-standard.org/standard/file/REQUIRE
\
\ 	: require ( i * x "name" -- j * x ) parse-name required ;

require w4/std/compile.f
\ require w4/std/exceptions.f
require w4/std/logic.f
require w4/std/loops.f
require w4/std/math.f
require w4/std/parse.f
require w4/std/stack.f
require w4/std/test.f
require w4/std/text.f

require w4/ext/debug.f
\ require w4/ext/hash.f

\
\ End of library
\
