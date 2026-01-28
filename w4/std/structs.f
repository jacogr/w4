m4_require(`std/loops.f')
m4_require(`std/memory.f')

\ https://forth-standard.org/standard/facility/BEGIN-STRUCTURE
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below. Return a
\ struct-sys (zero or more implementation dependent items) that will be used
\ by END-STRUCTURE and an initial offset of 0.
\
\ At runtime: +n is the size in memory expressed in address units of the data
\ structure. An ambiguous condition exists if name is executed prior to the
\ associated END-STRUCTURE being executed.

	: BEGIN-STRUCTURE  \ -- addr 0   ; exec: -- +n
		create
			here 0 0 ,     \ mark stack, lay dummy
		does> @          \ -- size
	;

\ https://forth-standard.org/standard/facility/END-STRUCTURE
\
\ Terminate definition of a structure started by BEGIN-STRUCTURE.

	: END-STRUCTURE	( addr n -- ) swap ! ;

\ https://forth-standard.org/standard/facility/PlusFIELD
\
\ Skip leading space delimiters. Parse name delimited by a space. Create a
\ definition for name with the execution semantics defined below. Return
\ n3 = n1 + n2 where n1 is the offset in the data structure before +FIELD
\ executes, and n2 is the size of the data to be added to the data structure.
\ n1 and n2 are in address units.

	: +FIELD  \ n <"name"> -- ; Exec: addr -- 'addr
		create over , +
		does> @ +
	;

\ https://forth-standard.org/standard/facility/FIELDColon
\
\ Skip leading space delimiters. Parse name delimited by a space. Offset is the
\ first cell aligned value greater than or equal to n1. n2 = offset + 1 cell.
\
\ Create a definition for name with the execution semantics given below.
\
\ At runtime: Add the offset calculated during the compile-time action to addr1
\ giving the address addr2.

	: FIELD: ( n1 "name" -- n2 ; addr1 -- addr2 ) aligned 1 cells +field ;
    : CFIELD: ( n1 "name" -- n2 ; addr1 -- addr2 ) 1 chars +field ;

	\ FUTURE If floats are available
	\
	\ : FFIELD:   ( n1 "name" -- n2 ; addr1 -- addr2 ) faligned 1 floats +field ;
    \ : SFFIELD:  ( n1 "name" -- n2 ; addr1 -- addr2 ) sfaligned 1 sfloats +field ;
    \ : DFFIELD:  ( n1 "name" -- n2 ; addr1 -- addr2 ) dfaligned 1 dfloats +field ;
