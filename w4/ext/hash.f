require ../std/loops.f

\ djb2a hash

	: djb2a ( c-addr u -- u ) \ ((hash << 5) + hash) ^ ch
		$1505 swap 0		( c-addr u -- c-addr hash u 0 -- )
		do					( c-addr hash u 0 -- c-addr hash )
			over i + c@		( c-addr hash --  c-addr hash ch )
			swap			( c-addr hash ch -- c-addr ch hash )
			#33 *			\ equivalent to (hash * 33) ^ ch
			xor
		loop
		nip					( c-addr hash -- hash )
	;

\ fnv1a hash

	: fnv1a ( c-addr u -- u ) \ (hash ^ ch) * prime
		$811c9dc5 swap 0	( c-addr u -- c-addr hash u 0 -- )
		do					( c-addr hash u 0 -- c-addr hash )
			over i + c@		( c-addr hash --  c-addr hash ch )
			xor	$01000193 *	( c-addr hash ch -- c-addr hash' )
		loop
		nip					( c-addr hash -- hash )
	;

\ host-compatible hash values for lookups

	: host::hash ( c-addr u -- hd hf )
		2dup		( c-addr u -- c-addr u c-addr u )
		fnv1a		( ... c-addr u -- c-addr u hf )
	 	>r djb2a r>	( c-addr u -- hd hf )
	;

	: host::hash'
		parse-name host::hash
	;
