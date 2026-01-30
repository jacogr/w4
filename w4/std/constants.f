
\ https://forth-standard.org/standard/core/HERE
\
\ a-addr is the data-space pointer.

	: (here^) ( -- a-addr ) $0100 ;
	: (here-min) ( -- u ) $0104 @ ;
	: (here-max) ( -- u ) $0108 @ ;

	: HERE ( -- a-addr ) (here^) @ ;

\ Helper for allot & aligned that checks and writes to the
\ underlying here pointer location to adavance here

	: (here!)	( a-addr -- )
		dup (here-max) - 	\ subtract from maxiumum memory position
		$80000000 and 0=	\ signed bit should not be set

		\ negative address? -23 address alignment exception
		#-23 and throw

		(here^) !			\ update address, underlying here pointer
	;

m4_require_w4(`std/constants-create.f')
m4_require_w4(`std/constants-structs.f')

\ builtin flags for the environment

	$c0de0000 constant (flg-is-any)
	$c0de0001 constant (flg-is-vis)
	$c0de0002 constant (flg-is-imm)
	$c0de0004 constant (flg-is-var)
	$c0de0010 constant (flg-xt-asm)
	$c0de0020 constant (flg-xt-tkn)
	$c0de0040 constant (flg-xt-lit)
	$c0de0080 constant (flg-xt-does)
	$c0de0100 constant (flg-xt-local)
	$feedca11 constant (flg-list)
	$babeca11 constant (flg-name)

\ environment constants

	$ff 1 + constant STRING-MAX

	$10 constant (env-locals#)
	$2f constant (env-stackmax#)
	$10 constant (env-wordlists-max#)
	#84 constant (env-padsize#)
	STRING-MAX constant (env-holdsize#)

\ https://forth-standard.org/standard/core/PAD
\
\ c-addr is the address of a transient region that can be used to hold data
\ for intermediate processing.
\
\ The size of the scratch area whose address is returned by PAD shall be
\ at least 84 characters. The contents of the region addressed by PAD are
\ intended to be under the complete control of the user: no words defined in
\ this standard place anything in the region. Non-standard words provided by
\ an implementation may use PAD, but such use shall be documented.

	(env-padsize#) buffer: PAD

\ control stack

	(env-stackmax#) 1 + cells buffer: (cs^)

\ Internal constant helpers for the exposed/host memory pointers

	: (mmio:) constant ;
	: (mmio@) constant does> @ ;

\ constants as exposed from the wasm environment

\ https://forth-standard.org/standard/core/SOURCE-ID
\ https://forth-standard.org/standard/file/SOURCE-ID
\
\ Identifies the input source as follows: -1 (string), 0 (io), fileid

	$0110 (mmio@) SOURCE-ID

\ https://forth-standard.org/standard/core/SOURCE
\
\ iov that wraps the source, >str+len for source c-addr u

	$0118 (mmio@) (lniov^)

\ latest executing token (latest definition already defined)

	$0124 (mmio@) (exec^)

\ https://forth-standard.org/standard/core/STATE
\
\ a-addr is the address of a cell containing the compilation-state flag.
\ STATE is true when in compilation state, false otherwise. The true value
\ in STATE is non-zero, but is otherwise implementation-defined.
\
\ Only the following standard words alter the value in STATE: : (colon),
\ ; (semicolon), ABORT, QUIT, :NONAME, [ (left-bracket), ] (right-bracket).

	$0130 (mmio:) STATE

\ https://forth-standard.org/standard/core/BASE
\
\ a-addr is the address of a cell containing the current number-conversion
\ radix {{2...36}}.

	$0134 (mmio:) BASE

\ https://forth-standard.org/standard/search/FORTH-WORDLIST
\
\ Return wid, the identifier of the word list that includes all standard words
\ provided by the implementation. This word list is initially the compilation
\ word list and is part of the initial search order.

	$0150 (mmio@) FORTH-WORDLIST
	$0154 (mmio@) (wid-curr) : (wid-curr!) $0154 ! ;
	$0158 (mmio@) (wid-list)
	$015c (mmio@) (wid-count) : (wid-count!) $015c ! ;

\ pointers for locals definitions

	$0160 (mmio:) (locals-base^)
	$0164 (mmio@) (locals-wid) : (locals-wid!) $0164 ! ;
