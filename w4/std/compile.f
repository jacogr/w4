m4_require_w4(`std/constants.f')
m4_require_w4(`std/logic.f')
m4_require_w4(`std/stack-rs.f')

\ Non-standard, but well-known

	: NOOP ( -- ) ;

\ https://forth-standard.org/standard/tools/BYE
\
\ Return control to the host operating system, if any.

	: BYE ( -- ) 0 >r ;

\ https://forth-standard.org/standard/core/Bracket
\
\ Enter interpretation state. [ is an immediate word.

	: [ ( -- ) #0 state ! ; immediate \ interpret state

\ https://forth-standard.org/standard/core/LITERAL
\
\ Append the run-time semantics given below to the current definition.
\
\ At runtime place x on the stack.

	: LITERAL ( x -- ) lit, ; immediate

\ https://forth-standard.org/standard/core/Tick
\
\ Skip leading space delimiters. Parse name delimited by a space. Find name
\ and return xt, the execution token for name.

	: ?PARSE-NAME ( "name" -- c-addr u ) parse-name dup 0= #-16 and throw ;

	: ?FIND-NAME ( c-addr u -- nt ) find-name dup 0= #-13 and throw ;

	: ' ( "name" -- xt ) ?parse-name ?find-name (nt>value@) ;

\ https://forth-standard.org/standard/core/BracketTick
\
\ Skip leading space delimiters. Parse name delimited by a space. Find name.
\ Append the run-time semantics given below to the current definition.
\
\ At runtime: Place name's execution token xt on the stack. The execution token
\ returned by the compiled phrase "['] X" is the same value returned by "' X"
\ outside of compilation state.

	: ['] ( -- xt ) ' lit, ; immediate

\ branchless select: return true if flag=-1, false if flag=0
\ matches C (cond ? true : false)
\ uses: false ^ ((false ^ true) & flag)

	: SELECT ( flag true false -- result )
		dup >r		( flag true false -- flag true false ) ( r: -- false )
		xor			( flag true false -- flag r1 )			\ r1 = (false^true)
		and r>		( flag r1 -- r2 false ) ( r: false -- )	\ r2 = r1 & flag
		xor			( f2 false -- result )					\ result = false ^ r2
	;

\ https://forth-standard.org/standard/tools/NAMEtoCOMPILE
\
\ x xt represents the compilation semantics of the word nt. The returned xt
\ has the stack effect ( i * x x -- j * x ). Executing xt consumes x and
\ performs the compilation semantics of the word represented by nt.

	: is-xt-immediate? ( xt -- f ) >flags @ $02 and 0<> ;

	: NAME>COMPILE ( nt -- xt action-xt )
		(nt>value@)					( nt -- xt )
  		dup is-xt-immediate?		( xt -- xt flag )
  		['] execute ['] compile,	( xt flag -- xt flag xte xtc )
		select						( xt flag xte xtc -- xt action-xt )
	;

\ https://forth-standard.org/standard/tools/NAMEtoINTERPRET
\
\ xt represents the interpretation semantics of the word nt. If nt has no
\ interpretation semantics, NAME>INTERPRET returns 0.
\
\ NOTE We _always_ assume that we can interpret anything, this includes all
\ immediate words as well. This assumption _may_ not be true in the future and
\ the _may_ need adjustment

	: NAME>INTERPRET ( nt -- xt ) (nt>value@) ;

\ https://forth-standard.org/standard/tools/NAMEtoSTRING
\
\ NAME>STRING returns the name of the word nt in the character string c-addr u.
\ The case of the characters in the string is implementation-dependent.
\
\ In this implementation we will output as defined, but can consume in a case-
\ insenstive manner

	: NAME>STRING ( nt -- c-addr u ) (nt>value@) (xt>str+len@) ;

\ https://forth-standard.org/standard/core/POSTPONE
\
\ Skip leading space delimiters. Parse name delimited by a space. Find name.
\ Append the compilation semantics of name to the current definition.

	: POSTPONE  ( "name" -- )
		?parse-name ?find-name		( "name" -- nt )

		\ only allowed in compilation, -48 invalid POSTPONE
		state @ 0= #-48 and throw

		name>compile				( nt -- xt action-xt )
		swap lit,					( xt action-xt -- xt )
		compile,					( xt -- )
	; immediate

\ https://forth-standard.org/standard/core/RECURSE
\
\ Append the execution semantics of the current definition to the current
\ definition.

	: RECURSE ( -- ) latest compile, ; immediate

\ https://forth-standard.org/standard/core/ColonNONAME
\
\ Create an execution token xt, enter compilation state and start the current
\ definition, producing colon-sys. Append the initiation semantics given below
\ to the current definition.
\
\ The execution semantics of xt will be determined by the words compiled into
\ the body of the definition. This definition can be executed later by using xt
\ EXECUTE.
\
\ At runtime: Execute the definition specified by xt. The stack effects i * x
\ and j * x represent arguments to and results from xt, respectively.

	parse-name :NONAME build,	\ create :noname (same structure as :)
		]						\ compile
		0 0 build, 				\ no name
		latest					\ put latest on the stack
		]						\ enter compilation, rest follows
	;
