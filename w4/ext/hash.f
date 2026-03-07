m4_require(<!std/control.f!>)
m4_require(<!std/math.f!>)
m4_require(<!std/stack-control.f!>)
m4_require(<!std/string-utils.f!>)

\ djb2a hash
\ loops: ((hash << 5) + hash) ^ ch
\
\ https://en.wikipedia.org/wiki/Daniel_J._Bernstein

	: DJB2A-i ( c-addr u -- u )
		$1505 swap				( c-addr u -- c-addr hash u -- )
		begin
			dup 0<>
		while					( c-addr hash u -- c-addr hash u )
			>r					( c-addr hash u -- c-addr hash ) ( r: -- u )
			over c@ >lower-ascii	( c-addr hash -- c-addr hash ch )
			swap dup			( c-addr hash ch -- c-addr ch hash hash )
			#5 lshift			( c-addr ch hash hash -- c-addr ch hash hash<<5 )
			+ xor				( c-addr ch hash hash<<5 -- c-addr hash )
			swap 1+ swap		( c-addr hash -- c-addr' hash )
			r> 1-				( c-addr' hash -- c-addr' hash u' )
		repeat
		drop nip				( c-addr hash 0 -- hash )
	;

\ fnv1a hash
\ loops: (hash ^ ch) * prime
\
\ https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function

	: FNV1A-i ( c-addr u -- u )
		$811c9dc5 swap			( c-addr u -- c-addr hash u )
		begin
			dup 0<>
		while					( c-addr hash u -- c-addr hash u )
			>r					( c-addr hash u -- c-addr hash ) ( r: -- u )
			over c@ >lower-ascii	( c-addr hash -- c-addr hash ch )
			xor	$01000193 *		( c-addr hash ch -- c-addr hash' )
			swap 1+ swap		( c-addr hash' -- c-addr' hash' )
			r> 1-				( c-addr' hash' -- c-addr' hash' u' )
		repeat
		drop nip				( c-addr hash 0 -- hash )
	;

\ fmix32
\
\ https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp

	: FMIX32 ( u -- u' )
		dup #16 rshift xor		\ h ^= h >> 16
		$85ebca6b *				\ h *= 0x85ebca6b
		dup #13 rshift xor		\ h ^= h >> 13
		$c2b2ae35 *				\ h *= 0xc2b2ae35
		dup #16 rshift xor		\ h ^= h >> 16
	;

\ host-compatible hash values for lookups, applies fmix32(fnv1a(value)), if
\ it is a non-zero string, else return 0 as the hash value

	: HOST::HASH ( c-addr u -- hash )
		\ len <> 0
		?dup 0<> if
			fnv1a-i fmix32
		else drop $0 then
	;
