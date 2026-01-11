
(;

	hash.wat

	Hashing as used in the lookup tables. Selection criteria is on being
	fast, small (it _can_ be expanded to i64 with an additional pass) and
	importantly being robust to not give an abundance of collisions.

	Other possibilities:

	https://github.com/hyperdivision/murmur3hash-wasm/blob/master/murmur3.wat

;)

	;; constants for fnv-1a
	(global $FNV1A_PRIME i32 (i32.const 0x01000193))
	(global $FNV1A_START i32 (i32.const 0x811c9dc5))

	;; constants for Murmur3 fmix32
	(global $FMIX32_C1 i32 (i32.const 0x85ebca6b))
	(global $FMIX32_C2 i32 (i32.const 0xc2b2ae35))

	;;
	;; Create a 32-bit non-cryptographic hash from fnv-1a followed by
	;; the fmix32 finalizer from Murmur3 to improve distribution
	;;
	;;
	(func $__hash (param $ptr i32) (param $len i32) (result i32)
		(call $__hash_fmix32
			(call $__hash_fnv1a (local.get $ptr) (local.get $len)))
	)

	;;
	;; FNV-1a 32-bit hashing
	;;
	;; https://en.wikipedia.org/wiki/Fowler%E2%80%93Noll%E2%80%93Vo_hash_function
	;;
	(func $__hash_fnv1a (param $ptr i32) (param $len i32) (result i32)
		(local $hash i32)
		(local $idx i32)

		;; set starting value
		(local.set $hash (global.get $FNV1A_START))

		;; loop through all characters
		(loop $loop

			;; calculate fnv1a
			;; (hash ^ ch) * prime
			(local.set $hash
				(i32.mul
					(i32.xor
						(local.get $hash)
						(call $__ch_lower (i32.load8_u (i32.add (local.get $ptr) (local.get $idx)))))
					(global.get $FNV1A_PRIME)))

			;; continue
			(br_if $loop
				(i32.lt_u
					(local.tee $idx (i32.add (local.get $idx) (i32.const 1)))
					(local.get $len))))

		;; return hash
		local.get $hash
	)

	;;
	;; Murmur3 fmix32 finalizer
	;;
	;; 		h ^= h >> 16
	;; 		h *= 0x85ebca6b
	;; 		h ^= h >> 13
	;; 		h *= 0xc2b2ae35
	;; 		h ^= h >> 16
	;;
	;; https://en.wikipedia.org/wiki/MurmurHash
	;;
	(func $__hash_fmix32 (param $hash i32) (result i32)
		;; h ^= h >> 16
		(local.set $hash
			(i32.xor
				(local.get $hash)
				(i32.shr_u (local.get $hash) (i32.const 16))))

		;; h *= FMIX32_C1
		(local.set $hash
			(i32.mul (local.get $hash) (global.get $FMIX32_C1)))

		;; h ^= h >> 13
		(local.set $hash
			(i32.xor
				(local.get $hash)
				(i32.shr_u (local.get $hash) (i32.const 13))))

		;; h *= FMIX32_C2
		(local.set $hash
			(i32.mul (local.get $hash) (global.get $FMIX32_C2)))

		;; h ^= h >> 16, final result
		(i32.xor
			(local.get $hash)
			(i32.shr_u (local.get $hash) (i32.const 16)))
	)
