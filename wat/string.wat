
(;

	string.wat

	String and character handling routines.

;)

	;;
	;; Calculate the string length for a c-style \0 terminated string
	;;
	(func $__strlen_z (param $str i32) (result i32)
		(local $len i32)

		;; loop until \0 is found
		(block $exit (loop $loop

			;; exit if \0 found
			(br_if $exit
				(i32.eqz (i32.load8_u (i32.add (local.get $str) (local.get $len)))))

			;; next character
			(local.set $len (i32.add (local.get $len) (i32.const 1)))

			;; continue
			br $loop))

		local.get $len
	)

	;;
	;; Compares 2 strings for equality
	;;
	;; Compare two byte strings for equality, case-insensitive (ASCII), length-limited.
	;; Returns 1 if equal, 0 otherwise.
	;;
	(func $__streqi_n (param $a i32) (param $b i32) (param $len i32) (result i32)
		(local $i i32)

		(block $exit (loop $loop
			;; done if length exhausted
			(br_if $exit
				(i32.ge_u (local.get $i) (local.get $len)))

			;; compare lower(a[i]) vs lower(b[i])
			(i32.eq
				(call $__ch_lower (i32.load8_u (i32.add (local.get $a) (local.get $i))))
				(call $__ch_lower (i32.load8_u (i32.add (local.get $b) (local.get $i))))) (if

				;; still matching, continue
				(then)

				;; mismatch found, return 0
				(else (return (i32.const 0))))

			;; i++
			(local.set $i (i32.add (local.get $i) (i32.const 1)))

			;; continue
			br $loop))

		;; match found
		i32.const 1
	)

	;;
	;; Duplicates a string into a stable/non-transient buffer
	;;
	(func $__strdup_n (param $src i32) (param $len i32) (result i32)
		(local $dst i32)

		;; copy
		(memory.copy
			(local.tee $dst (call $__alloc (i32.add (local.get $len) (i32.const 1))))
			(local.get $src)
			(local.get $len))

		;; return dst
		local.get $dst
	)

	;;
	;; Find the occurence of a character in a string, -1 if
	;; not found, else the position
	;;
	;; returns index of last char or -1 if not found
	(func $__strposr (param $ch i32) (param $ptr i32) (param $len i32) (result i32)
		(local $i i32)

		(local.set $i (local.get $len))

		(block $exit (loop $loop
			;; -1, not found
			(br_if $exit
				(i32.eq
					(local.tee $i (i32.sub (local.get $i) (i32.const 1)))
					(i32.const -1)))

			;; if ptr[i] == ch
			(br_if $exit
				(i32.eq
					(i32.load8_u (i32.add (local.get $ptr) (local.get $i)))
					(local.get $ch)))

			;; next position
			br $loop))

		;; return last position
		local.get $i
	)

	;;
	;; Returns a character value if it would end a line
	;;
	;; Returns a non-zero (4 for eof/eos, 10 for eol) if the line
	;; is at the end, otherwise return a zero value
	;;
	(func $__ch_is_eol (param $ch i32) (result i32)
		;; eol?
		(i32.eq (local.get $ch) (i32.const 10)) (if (result i32)

			;; eol found
			(then (i32.const 10))

			;; not eol, check eof
			(else
				(select
					;; eof?
					(i32.const 4)
					;; non-ending
					(i32.const 0)
					;; eof?
					(i32.or
						(i32.eqz (local.get $ch))
						(i32.eq (local.get $ch) (i32.const 4))))))
	)

	;;
	;; Returns a character value if it would end a word (eol or space/tab)
	;;
	;; In our implementation we follow
	;;
	;; https://forth-standard.org/standard/usage#subsubsection.3.4.1.1
	;; https://forth-standard.org/standard/usage#subsubsection.3.1.2.2
	;;
	;; From 3.4.1.1 Delimiters: If the delimiter is the space character, hex 20 (BL)
	;; control character may be treated as delimiters
	;;
	(func $__ch_is_eow (param $ch i32) (result i32)
		(local $eol i32)

		;; check for characters that end the line - this is not handled
		;; as part of the control check since we treat \0 the same as an eof
		(i32.and
			(i32.eqz (local.tee $eol (call $__ch_is_eol (local.get $ch))))
			(i32.le_u (local.get $ch) (i32.const 32))) (if (result i32)

			;; it is an eow character
			(then (local.get $ch))

			;; no eol, check for <= 32 (space, hex 0x20)
			(else (local.get $eol)))
	)

	;;
	;; Lowercase version of a character
	;;
	(func $__ch_lower (param $ch i32) (result i32)
		;; ch >= 'A' (65) & ch <= 'Z' (90)
		(i32.and
			(i32.ge_u (local.get $ch) (i32.const 65))
			(i32.le_u (local.get $ch) (i32.const 90))) (if (result i32)

			;; uppercase, lowercase it
			(then (i32.or (local.get $ch) (i32.const 32)))

			;; use as-is
			(else (local.get $ch)))
	)
