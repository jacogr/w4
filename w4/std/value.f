require memory.f

\ https://forth-standard.org/standard/core/VALUE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below, with an
\ initial value equal to x.
\
\ At runtime: Place x on the stack. The value of x is that given when name
\ was created, until the phrase x TO name is executed, causing a new value
\ of x to be assigned to name.

	: value ( x "name" -- ) create , does> @ ;

\ https://forth-standard.org/standard/double/TwoVALUE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below, with an
\ initial value of x1 x2.
\
\ Place cell pair x1 x2 on the stack. The value of x1 x2 is that given when
\ name was created, until the phrase "x1 x2 TO name" is executed, causing a
\ new cell pair x1 x2 to be assigned to name.

	: 2value ( x1 x2 "name" -- ) create 2, does> 2@ ;

\ https://forth-standard.org/standard/core/TO
\
\ Interpretation: Skip leading spaces and parse name delimited by a space.
\ Perform the "TO name run-time" semantics given in the definition for the
\ defining word of name. An ambiguous condition exists if name was not defined
\ by a word with "TO name run-time" semantics.

	: (to)  ( x a-addr -- ) ! ;

	: to ( x "name" -- )
		' >body				( x a-addr )
		state @ if
			swap lit, lit,	\ runtime: push x first
			postpone (to)
		else (to) then
	; immediate

\ Non-standard, well-known. Same as to but with +! semantics

	: (+to) ( x a-addr -- ) +! ;

	: +to ( x "name" -- )
		' >body 			( x a-addr )
		state @ if
			swap lit, lit,	\ runtime: push x first
			postpone (+to)
		else (+to) then
	; immediate

\ Non-standard, well-known. As per the single-cell version, same semantics.

	: (2to)  ( x1 x2 a-addr -- ) 2! ;

	: 2to ( x1 x2 "name" -- )
		' >body 			( x1 x2 a-addr )
		state @ if
			>r swap r> 		( x2 x1 a-addr )
			lit, lit, lit,
			postpone (2to)
		else (2to) then
	; immediate

\ Non-standard, well-known. As per the single-cell version, same semantics.

	: (2+to) ( x1 x2 a-addr -- )
		>r 		( x1 x2 )
		r@ 2@ 	( x1 x2 y1 y2 )
		d+ 		( z1 z2 )
		r> 2!
	;

	: 2+to ( x1 x2 "name" -- )
		' >body 			( x1 x2 a-addr )
		state @ if
			>r swap r> 		( x2 x1 a-addr )  \ TOS sequence: a-addr then x1 then x2? see below
			lit, lit, lit,
			postpone (2+to)
		else (2+to) then
	; immediate

\ https://forth-standard.org/standard/core/BUFFERColon
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name, with the execution semantics defined below. Reserve u
\ address units at an aligned address. Contiguity of this region with any
\ other region is undefined.
\
\ At runtime: a-addr is the address of the space reserved by BUFFER: when it
\ defined name. The program is responsible for initializing the contents.

	: buffer: ( u "<name>" -- addr )
		create allot
	;
