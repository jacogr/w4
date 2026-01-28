
	#32 parse-token ] build, 1 $0130 ! 1 $0130 ! ;
	#32 parse-token : build, ] #32 parse-token build, ] ;

	: PARSE-NAME #32 parse-token ;
	: REQUIRE parse-name required ;

m4_include(`preclude.m4')
m4_require(`preamble.f')

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
\		1 $0130 ! 		\ compile, 1 state ! (state constant not defined yet)
\		1 $0130 !		\ apply when executed
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
\	: PARSE-NAME ( -- c-addr u ) #32 parse-token ;

\ https://forth-standard.org/standard/file/REQUIRE
\
\ Skip leading white space and parse name delimited by a white space
\ character. Push the address and length of the name on the stack and
\ perform the function of REQUIRED.
\
\ 	: REQUIRE ( i * x "name" -- j * x ) parse-name required ;

m4_require(`std/constants.f')
m4_require(`std/compile.f')
m4_require(`std/dictionary.f')
m4_require(`std/environment.f')
m4_require(`std/exceptions.f')
m4_require(`std/locals.f')
m4_require(`std/logic.f')
m4_require(`std/logic.number.f')
m4_require(`std/loops.f')
m4_require(`std/math.f')
m4_require(`std/math.double.f')
m4_require(`std/memory.f')
m4_require(`std/parse.f')
m4_require(`std/search.f')
m4_require(`std/search.string.f')
m4_require(`std/stack.f')
m4_require(`std/stack.loop.f')
m4_require(`std/stack.ptr.f')
m4_require(`std/stdio.f')
m4_require(`std/string.f')
m4_require(`std/string.utils.f')
m4_require(`std/structs.f')
m4_require(`std/test.f')
m4_require(`std/text.f')
m4_require(`std/value.f')

m4_require(`ext/debug.f')
m4_require(`ext/hash.f')
m4_require(`ext/is.f')
m4_require(`ext/list.f')
m4_require(`ext/unimplemented.f')
m4_require(`ext/wasi.f')
