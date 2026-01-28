m4_require_w4(`std/constants.f')

m4_require_w4(`ext/wasi.f')

\ https://forth-standard.org/standard/file/RDivO
\
\ fam is the implementation-defined value for selecting the "read only" file access method.

	0 constant R/O

\ https://forth-standard.org/standard/file/WDivO
\
\ fam is the implementation-defined value for selecting the "write only" file access method.

	1 constant W/O

\ https://forth-standard.org/standard/file/RDivW
\
\ fam is the implementation-defined value for selecting the "read/write" file access method.

	2 constant R/W
