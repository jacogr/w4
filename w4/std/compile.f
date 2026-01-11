require parse.f
require stack.f

\ Non-standard, but well-known

	: noop ( -- ) ;

\ https://forth-standard.org/standard/tools/BYE

	: bye ( -- ) 0 >r ;

\ https://forth-standard.org/standard/core/Bracket

	: [ ( -- ) #0 state ! ; immediate \ interpret state

\ https://forth-standard.org/standard/core/Comma
\
\ FIXME: This is not _quite_ compliant. In normal compilers, this
\ would take _any_ stack value and compile it, we need an xt on
\ the stack, i.e. 15 compile, will fail.
\
\ Needs a further check.

	: , ( xt -- ) compile, ;

\ https://forth-standard.org/standard/core/LITERAL

	: literal ( -- x ) lit, ; immediate

\ branchless select: return true if flag=-1, false if flag=0
\ matches C (cond ? true : false)
\ uses: false ^ ((false ^ true) & flag)

	: select ( flag true false -- result )
		swap		\ flag false true
		over xor	\ flag false (false^true)
		rot and		\ false ((false^true)&flag)
		xor			\ false ^ ((false^true)&flag) => result
	;

\ https://forth-standard.org/standard/tools/NAMEtoCOMPILE

	' execute  constant (xt-execute)
	' compile, constant (xt-compile,)

	: name>compile ( nt -- xt action-xt )
		name>xt						( nt -- xt )
  		dup >flags @ $02 and 0=		( xt -- xt flag )
  		(xt-compile,) (xt-execute)	( xt flag -- xt flag xtc xte )
		select						( xt flag xtc xte -- xt action-xt )
	;

\ https://forth-standard.org/standard/tools/NAMEtoINTERPRET

	: name>interpret ( nt -- xt ) name>xt ;

\ https://forth-standard.org/standard/tools/NAMEtoSTRING

	: name>string ( nt -- c-addr u ) name>xt >string ;

\ https://forth-standard.org/standard/core/POSTPONE

	: postpone  ( "name" -- )
		?parse-name ?find-name		( "name" -- nt )
		state @ 0= #-48 and throw	\ only allowed in compilation state
		name>compile				( nt -- xt action-xt )
		swap lit,					( xt action-xt -- xt )
		compile,					( xt -- )
	; immediate

\ https://forth-standard.org/standard/core/DEFER

	\ : defer ( "name" -- )
	\ 	create ['] abort ,
	\ 	does> ( ... -- ... )
   	\ 	@ execute
	\ ;

\ https://forth-standard.org/standard/core/RECURSE

	: recurse  ( -- )
		latest name>xt			( -- xt )
		compile,				( -- )
	; immediate

