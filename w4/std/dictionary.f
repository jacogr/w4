m4_require(`std/constants.f')
m4_require(`std/logic.f')
m4_require(`std/loops.f')
m4_require(`std/stack.f')
m4_require(`std/text.f')

\ TODO See if we should include this is search.f which deals
\ with all things related to wordlists (and maybe rename it as well)

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

	: (latest-nt) (wid-curr) (lst>tail@) ;

	: (marker) ( nt -- )
		begin
			?dup
		while
			dup (nt>value@)	( nt -- nt xt )
			(hide)			( nt xt -- nt )
			(nt>next@)		( nt -- nt' )
			dup 0=			( nt -- nt f )
		until

		drop
	;

	: MARKER ( <spaces>name" -- )
		parse-name				( -- c-addr u )

		\ -16 attempt to use zero-length string as a name
		dup 0= #-16 and throw

		build,					\ definition for "name"
		(latest-nt) lit,		\ compile marker nt to body
		postpone (marker)		\ execute (marker) ( nt -- )
		reveal					\ set visible
	;
