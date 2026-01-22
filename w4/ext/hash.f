require ../std/loops.f

\ djb2a hash
\ loops: ((hash << 5) + hash) ^ ch
\
\ https://en.wikipedia.org/wiki/Daniel_J._Bernstein

	: djb2a ( c-addr u -- u )
		$1505 swap			( c-addr u -- c-addr hash u -- )
		0 ?do				( c-addr hash u 0 -- c-addr hash )
			over i + c@		( c-addr hash --  c-addr hash ch )
			swap dup		( c-addr hash ch -- c-addr ch hash hash )
			5 lshift		( c-addr ch hash hash -- c-addr ch hash hash<<5 )
			+ xor			( c-addr ch hash hash<<5 -- c-addr hash )	\ ((hash << 5) + hash) ^ ch
		loop
		nip					( c-addr hash -- hash )
	;

\ fnv1a hash
\ loops: (hash ^ ch) * prime
\
\ https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function

	: fnv1a ( c-addr u -- u )
		$811c9dc5 swap		( c-addr u -- c-addr hash u )
		0 ?do				( c-addr hash u 0 -- c-addr hash )
			over i + c@		( c-addr hash --  c-addr hash ch )
			xor	$01000193 *	( c-addr hash ch -- c-addr hash' )
		loop
		nip					( c-addr hash -- hash )
	;

\ fmix32
\
\ https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp

	: fmix32 ( u -- u' )
		dup 16 rshift xor	\ h ^= h >> 16
		$85ebca6b *		\ h *= 0x85ebca6b
		dup 13 rshift xor	\ h ^= h >> 13
		$c2b2ae35 *		\ h *= 0xc2b2ae35
		dup 16 rshift xor	\ h ^= h >> 16
	;

\ host-compatible hash values for lookups, applies fmix32(fnv1a(value)), if
\ it is a non-zero string, else return 0 as the hash value

	: host::hash ( c-addr u -- hash )
		\ len <> 0
		?dup 0<> if
			fnv1a fmix32
		else drop 0 then
	;

