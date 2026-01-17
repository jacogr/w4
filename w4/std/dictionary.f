require constants.f
require logic.f
require loops.f
require stack.f

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

	: (marker)
		-1 throw \ umimplemented
	;

	: marker ( <spaces>name" -- )
		parse-name				( -- c-addr u )
		dup 0= #-16 and throw
		build,
		latest lit,				\ compile market pointer to body
		['] (marker) compile,	\ execute (marker) ( latest^ -- )
		reveal
	;
