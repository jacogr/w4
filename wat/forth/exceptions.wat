
(;

	forth/exceptions.wat

	Exception codes as mapped from the Forth standard tables. In addition
	to definition, it alos allows for setup and lookup.

;)

	;; mapping of exception codes to strings
	;; (space for 80 codes)
	(data (i32.const 1264)) ;; PTR_EXCEP_CODE

	;; actual exception strings, 1264 + 160 = 1424
	(data (i32.const 1424) ;; PTR_EXCEP_TEXT
		(;  -1 ;) "ABORT\00"
		(;  -2 ;) "ABORT\"\00"
		(;  -3 ;) "stack overflow\00"
		(;  -4 ;) "stack underflow\00"
		(;  -5 ;) "return stack overflow\00"
		(;  -6 ;) "return stack underflow\00"
		(;  -7 ;) "do-loops nested too deeply during execution\00"
		(;  -8 ;) "dictionary overflow\00"
		(;  -9 ;) "invalid memory address\00"
		(; -10 ;) "division by zero\00"
		(; -11 ;) "result out of range\00"
		(; -12 ;) "argument type mismatch\00"
		(; -13 ;) "undefined word\00"
		(; -14 ;) "interpreting a compile-only word\00"
		(; -15 ;) "invalid FORGET\00"
		(; -16 ;) "attempt to use zero-length string as a name\00"
		(; -17 ;) "pictured numeric output string overflow\00"
		(; -18 ;) "parsed string overflow\00"
		(; -19 ;) "definition name too long\00"
		(; -20 ;) "write to a read-only location\00"
		(; -21 ;) "unsupported operation\00"
		(; -22 ;) "control structure mismatch\00"
		(; -23 ;) "address alignment exception\00"
		(; -24 ;) "invalid numeric argument\00"
		(; -25 ;) "return stack imbalance\00"
		(; -26 ;) "loop parameters unavailable\00"
		(; -27 ;) "invalid recursion\00"
		(; -28 ;) "user interrupt\00"
		(; -29 ;) "compiler nesting\00"
		(; -30 ;) "obsolescent feature\00"
		(; -31 ;) ">BODY used on non-CREATEd definition\00"
		(; -32 ;) "invalid name argument\00"
		(; -33 ;) "block read exception\00"
		(; -34 ;) "block write exception\00"
		(; -35 ;) "invalid block number\00"
		(; -36 ;) "invalid file position\00"
		(; -37 ;) "file I/O exception\00"
		(; -38 ;) "non-existent file\00"
		(; -39 ;) "unexpected end of file\00"
		(; -40 ;) "invalid BASE for floating point conversion\00"
		(; -41 ;) "loss of precision\00"
		(; -42 ;) "floating-point divide by zero\00"
		(; -43 ;) "floating-point result out of range\00"
		(; -44 ;) "floating-point stack overflow\00"
		(; -45 ;) "floating-point stack underflow\00"
		(; -46 ;) "floating-point invalid argument\00"
		(; -47 ;) "compilation word list deleted\00"
		(; -48 ;) "invalid POSTPONE\00"
		(; -49 ;) "search-order overflow\00"
		(; -50 ;) "search-order underflow\00"
		(; -51 ;) "compilation word list changed\00"
		(; -52 ;) "control-flow stack overflow\00"
		(; -53 ;) "exception stack overflow\00"
		(; -54 ;) "floating-point underflow\00"
		(; -55 ;) "floating-point unidentified fault\00"
		(; -56 ;) "QUIT\00"
		(; -57 ;) "exception in sending or receiving a character\00"
		(; -58 ;) "[IF], [ELSE], or [THEN] exception\00"
		(; -59 ;) "invalid floating-point number\00"
		(; -60 ;) "file I/O error\00"
		;; (; -61 ;) "file I/O exception (implementation-defined)\00"
		;; (; -62 ;) "file I/O exception (implementation-defined)\00"
		;; (; -63 ;) "file I/O exception (implementation-defined)\00"
		;; (; -64 ;) "file I/O exception (implementation-defined)\00"
		;; (; -65 ;) "file I/O exception (implementation-defined)\00"
		;; (; -66 ;) "file I/O exception (implementation-defined)\00"
		;; (; -67 ;) "file I/O exception (implementation-defined)\00"
		;; (; -68 ;) "file I/O exception (implementation-defined)\00"
		;; (; -69 ;) "file I/O exception (implementation-defined)\00"
		;; (; -70 ;) "file I/O exception (implementation-defined)\00"
		;; (; -71 ;) "file I/O exception (implementation-defined)\00"
		;; (; -72 ;) "file I/O exception (implementation-defined)\00"
		;; (; -73 ;) "file I/O exception (implementation-defined)\00"
		;; (; -74 ;) "file I/O exception (implementation-defined)\00"
		;; (; -75 ;) "file I/O exception (implementation-defined)\00"
		;; (; -76 ;) "file I/O exception (implementation-defined)\00"
		;; (; -77 ;) "file I/O exception (implementation-defined)\00"
		;; (; -78 ;) "file I/O exception (implementation-defined)\00"
		;; (; -79 ;) "file I/O exception (implementation-defined)\00"
	)

	;;
	;; Build exception offset table for -1..-79 based on the packed string blob
	;; and return total blob size (including NUL terminators).
	;;
	;; Requires: strings are stored in order for -1..-79, each NUL-terminated.
	;;
	;; Returns the address after the last string
	;;
	(func $__excep_init (result i32)
		(local $i i32)
		(local $ptr i32)
		(local $len i32)

		(local.set $i (i32.const 1))
		(local.set $ptr (global.get $PTR_EXCEP_TEXT))

		(loop $loop
			;; table[i] = (u16) absolute pointer to string
			(i32.store16
				(i32.add
					(global.get $PTR_EXCEP_CODE)
					(i32.shl (local.get $i) (i32.const 1)))
				(local.get $ptr))

			;; ptr += len + 1
			(local.set $ptr
				(i32.add
					(local.get $ptr)
					(i32.add
						(call $__strlen_z (local.get $ptr))
						(i32.const 1))))

			;; next if i + 1 <= 79
			(br_if $loop
				(i32.le_u
					(local.tee $i (i32.add (local.get $i) (i32.const 1)))
					(i32.const 79))))

		;; last pointer
		local.get $ptr
	)

	;;
	;; Lookup standard Forth exception description (Table 9.1)
	;;
	;; in:   code (i32), e.g. -10
	;; out:  ptr to NUL-terminated ASCII string, or 0 if unknown/out of range
	;;
	(func $__excep_lookup (param $code i32) (result i32)
		;; i > -1 or i < -79
		(i32.or
			(i32.gt_s (local.get $code) (i32.const -1))
			(i32.lt_s (local.get $code) (i32.const -79))) (if (result i32)

			;; not found
			(then (i32.const 0))

			;; have it
			(else
				;; get pointer
				(i32.load16_u
					(i32.add
						(global.get $PTR_EXCEP_CODE)
						(i32.shl
							(i32.sub (i32.const 0) (local.get $code))
							(i32.const 1))))))
	)
