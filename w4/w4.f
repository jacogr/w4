
	#32 parse-token ] build, 1 $0150 ! 1 $0150 ! ;
	#32 parse-token : build, ] #32 parse-token build, ] ;

	: parse-name #32 parse-token ;
	: require parse-name required ;

require preamble.f

\
\ From here we should now be able to actually (mostly) parse
\ normal code, we have line comments and we have (inline) stack
\ comments so definitions can appear to be "normal"
\

\ https://forth-standard.org/standard/right-bracket
\
\ Enter compilation state.
\
\	#32 parse-token ] build,	\ define "]"
\		1 $0050 ! 		\ compile, 1 state ! (state constant not defined yet)
\		1 $0050 !		\ apply when executed
\	;

\ https://forth-standard.org/standard/core/Colon
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name, called a "colon definition". Enter compilation state
\ and start the current definition/ Append the initiation semantics given
\ below to the current definition.
\
\ The execution semantics of name will be determined by the words compiled
\ into the body of the definition. The current definition shall not be findable
\ in the dictionary until it is ended.
\
\	#32 parse-token : build,		\ define ":"
\		]							\ switch to compile
\		build, #32 parse-token ] 	\ apply "build, parse-name ]" to children
\	;

\ https://forth-standard.org/standard/core/PARSE-NAME
\
\ Skip leading space delimiters. Parse name delimited by a space.
\
\ c-addr is the address of the selected string within the input buffer and
\ u is its length in characters. If the parse area is empty or contains only
\ white space, the resulting string has length zero.
\
\	: parse-name ( -- c-addr u ) #32 parse-token ;

\ https://forth-standard.org/standard/file/REQUIRE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of REQUIRED.
\
\ 	: require ( i * x "name" -- j * x ) parse-name required ;

require std/constants.f
require std/compile.f
require std/dictionary.f
require std/exceptions.f
require std/list.f
require std/logic.f
require std/logic.number.f
require std/loops.f
require std/math.f
require std/math.double.f
require std/memory.f
require std/parse.f
require std/search.f
require std/search.string.f
require std/stack.f
require std/stack.loop.f
require std/stack.ptr.f
require std/stdio.f
require std/string.f
require std/string.utils.f
require std/test.f
require std/text.f
require std/unimplemented.f
require std/value.f
require std/wasi.f

require ext/debug.f
require ext/hash.f
require ext/is.f

\
\ End of library
\
