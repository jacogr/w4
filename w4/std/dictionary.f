require constants.f
require logic.f
require loops.f
require stack.f
require text.f

\ https://forth-standard.org/standard/core/MARKER
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below.
\
\ At runtime: Restore all dictionary allocation and search order pointers
\ to the state they had just prior to the definition of name. Remove the
\ definition of name and all subsequent definitions. Restoration of any
\ structures still existing that could refer to deleted definitions or
\ deallocated data space is not necessarily provided. No other contextual
\ information such as numeric base is affected.

	: (latest-nt) (dict^) (lst>tail@) ;

	: (marker) ( nt -- )
		begin
			?dup
		while
			dup (nt>value@)	( nt -- nt xt )

			\ reverse of reveal in constants.f
			>flags			( nt xt -- nt flags-addr )
			dup @			( nt flags-addr -- nt flags-addr flags )
			$-2 and			( nt flags-addr flags -- nt flags-addr flags' )
			swap !			( nt flags-addr flags' -- nt )

			(nt>next@)		( nt -- nt' )
			dup 0=
		until

		drop
	;

	: MARKER ( <spaces>name" -- )
		parse-name				( -- c-addr u )
		dup 0= #-16 and throw
		build,					\ definition for "name"
		(latest-nt) lit,		\ compile marker nt to body
		postpone (marker)		\ execute (marker) ( nt -- )
		reveal					\ set visible
	;
