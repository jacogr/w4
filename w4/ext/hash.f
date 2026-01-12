require ../std/loops.f

\ djb2a hash
\ loops: ((hash << 5) + hash) ^ ch

	: djb2a ( c-addr u -- u )
		$1505 swap 0		( c-addr u -- c-addr hash u 0 -- )
		do					( c-addr hash u 0 -- c-addr hash )
			over i + c@		( c-addr hash --  c-addr hash ch )
			swap			( c-addr hash ch -- c-addr ch hash )
			5 lshift xor	\ equivalent to (hash << 5) ^ ch
		loop
		nip					( c-addr hash -- hash )
	;

\ fnv1a hash
\ loops: (hash ^ ch) * prime

	: fnv1a ( c-addr u -- u )
		$811c9dc5 swap 0	( c-addr u -- c-addr hash u 0 -- )
		do					( c-addr hash u 0 -- c-addr hash )
			over i + c@		( c-addr hash --  c-addr hash ch )
			xor	$01000193 *	( c-addr hash ch -- c-addr hash' )
		loop
		nip					( c-addr hash -- hash )
	;

\ fmix32

	: fmix32 ( u -- u' )
		dup 16 rshift xor	\ h ^= h >> 16
		$85ebca6b *		\ h *= 0x85ebca6b
		dup 13 rshift xor	\ h ^= h >> 13
		$c2b2ae35 *		\ h *= 0xc2b2ae35
		dup 16 rshift xor	\ h ^= h >> 16
	;

\ host-compatible hash values for lookups

	: host::hash ( c-addr u -- u ) fnv1a fmix32	;

	: host::hash'
		parse-name host::hash
	;
