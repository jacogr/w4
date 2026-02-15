
(;

	forth/builtins.wat

	Definitions for the built-in words, i.e. those implemented
	directly in WASM. This should always be relatively minimal,
	in a perfect world we have as much as possible implemented
	directly in w4.f

;)

	;; call table for the builtins (max 32 allowed based on memory layouts)
	(type $TypeForthFn (func))
	(table 32 funcref)

	;; does derived operations
	(data (i32.const 980) "does:mark") ;; PTR_DO_MARK_TEXT, length = 10
	(data (i32.const 990) "does:exec") ;; PTR_DO_EXEC_TEXT, length = 10

	;; names & flags for native functions
	(data (i32.const 1000) ;; PTR_NATIVE_TEXT
		(;  0 ;) "exit"					"\00\00"
		(;  1 ;) "build,"				"\00\00"
		(;  2 ;) ";"					"\00\ff"
		(;  3 ;) "does>"				"\00\ff"
		(;  4 ;) "@"					"\00\00"
		(;  5 ;) "!"					"\00\00"
		(;  6 ;) "0="					"\00\00"
		(;  7 ;) "lshift"				"\00\00"
		(;  8 ;) "rshift"				"\00\00"
		(;  9 ;) "+"					"\00\00"
		(; 10 ;) "-"					"\00\00"
		(; 11 ;) "um*/mod"				"\00\00"
		(; 12 ;) "m*/mod"				"\00\00"
		(; 13 ;) "and"					"\00\00"
		(; 14 ;) "xor"					"\00\00"
		(; 15 ;) "or"					"\00\00"
		(; 16 ;) "find-name"			"\00\00"
		(; 17 ;) "parse-token"			"\00\00"
		(; 18 ;) "(execute)"			"\00\00"
		(; 19 ;) "(compile,)"			"\00\00"
		(; 20 ;) "throw"				"\00\00"
		(; 21 ;) "wasi::fd_write"		"\00\00"
		(; 22 ;) "wasi::fd_read"		"\00\00"
		(; 23 ;) "wasi::fd_close"		"\00\00"
		(; 24 ;) "wasi::path_open"		"\00\00"
		(;  z ;)
	)

	;; https://forth-standard.org/standard/core/EXIT
	;; R: ( x -- )
	(elem (i32.const  0) $__forth_fn_exit) ;; IMPORTANT Keep at 0
	(func $__forth_fn_exit (type $TypeForthFn)
		(call $__internal_exit)
	)

	;; https://forth-standard.org/standard/core/Colon
	;; ( c-addr u -- )
	(elem (i32.const 1) $__forth_fn_builds)
	(func $__forth_fn_builds (type $TypeForthFn)
		(call $__internal_builds (call $__stack_dat_2pop))
	)

	;; https://forth-standard.org/standard/core/Semi
	;; ( -- )
	(elem (i32.const  2) $__forth_fn_compile_end)
	(func $__forth_fn_compile_end (type $TypeForthFn)
		(call $__internal_compile_end)
	)

	;; https://forth-standard.org/standard/core/DOES
	;; ( -- )
	(elem (i32.const  3) $__forth_fn_does)
	(func $__forth_fn_does (type $TypeForthFn)
		(call $__internal_does)
	)

	;; https://forth-standard.org/standard/core/Fetch
	;; ( a-addr -- x )
	(elem (i32.const  4) $__forth_fn_fetch)
	(func $__forth_fn_fetch (type $TypeForthFn)
		(local $addr i32)

		(call $__assert_ptr (local.tee $addr (call $__stack_dat_pop)))
		(call $__stack_dat_push (i32.load (local.get $addr)))
	)

	;; https://forth-standard.org/standard/core/Store
	;; ( x a-addr -- )
	(elem (i32.const  5) $__forth_fn_store)
	(func $__forth_fn_store (type $TypeForthFn)
		(local $addr i32)

		;; ensure writable area, -20 write to a read-only location
		(call $__assert
			(i32.and
				(i32.ge_u
					(local.tee $addr (call $__stack_dat_pop))
					(global.get $SIZEOF_MEMORY_RO))
				(i32.le_u
					(local.get $addr)
					(i32.load (global.get $PTR_ALLOC))))
			(i32.const -20))

		(i32.store (local.get $addr) (call $__stack_dat_pop))
	)

	;; https://forth-standard.org/standard/core/ZeroEqual
	;; ( x -- flag )
	(elem (i32.const  6) $__forth_fn_eqz)
	(func $__forth_fn_eqz (type $TypeForthFn)
		(call $__stack_dat_push
			(select
				;; <> 0, no bits set
				(i32.const 0)
				;; == 0, set all bits
				(i32.const -1)
				;; == 0 ?
				(call $__stack_dat_pop)))
	)

	;; https://forth-standard.org/standard/core/LSHIFT
	;; ( x y -- n )
	(elem (i32.const  7) $__forth_fn_lshift)
	(func $__forth_fn_lshift (type $TypeForthFn)
		(call $__stack_dat_push
			(i32.shl (call $__stack_dat_2pop)))
	)

	;; https://forth-standard.org/standard/core/RSHIFT
	;; ( x y -- n )
	(elem (i32.const  8) $__forth_fn_rshift)
	(func $__forth_fn_rshift (type $TypeForthFn)
		(call $__stack_dat_push
			(i32.shr_u (call $__stack_dat_2pop)))
	)

	;; https://forth-standard.org/standard/core/Plus
	;; ( x y -- n )
	(elem (i32.const  9) $__forth_fn_add)
	(func $__forth_fn_add (type $TypeForthFn)
		(call $__stack_dat_push
			(i32.add (call $__stack_dat_2pop)))
	)

	;; https://forth-standard.org/standard/core/Minus
	;; ( x y -- z )
	(elem (i32.const 10) $__forth_fn_sub)
	(func $__forth_fn_sub (type $TypeForthFn)
		(call $__stack_dat_push
			(i32.sub (call $__stack_dat_2pop)))
	)

	;; non-standard toolbox for unsigned math
	(elem (i32.const 11) $__forth_fn_um_star_slash_mod)
	(func $__forth_fn_um_star_slash_mod (type $TypeForthFn)
		(local $lo i32)
		(local $hi i32)
		(local $mul i32)
		(local $div i32)
		(local $qhi i32)
		(local $qlo i32)
		(local $rem i32)

		(local.set $div (call $__stack_dat_pop))
		(local.set $mul (call $__stack_dat_pop))
		(local.set $hi (call $__stack_dat_pop))
		(local.set $lo (call $__stack_dat_pop))

		;; perform operation
		(call $__um_star_slash_mod
			(local.get $lo)
			(local.get $hi)
			(local.get $mul)
			(local.get $div))

		;; gather results
		(local.set $qhi)
		(local.set $qlo)
		(local.set $rem)

		;; push to stack
		(call $__stack_dat_push (local.get $rem))
		(call $__stack_dat_push (local.get $qlo))
		(call $__stack_dat_push (local.get $qhi))
	)

	;; non-standard toolbox for signed math
	(elem (i32.const 12) $__forth_fn_m_star_slash_mod)
	(func $__forth_fn_m_star_slash_mod (type $TypeForthFn)
		(local $lo i32)
		(local $hi i32)
		(local $mul i32)
		(local $div i32)
		(local $qhi i32)
		(local $qlo i32)
		(local $rem i32)

		(local.set $div (call $__stack_dat_pop))
		(local.set $mul (call $__stack_dat_pop))
		(local.set $hi (call $__stack_dat_pop))
		(local.set $lo (call $__stack_dat_pop))

		;; perform operation
		(call $__m_star_slash_mod
			(local.get $lo)
			(local.get $hi)
			(local.get $mul)
			(local.get $div))

		;; gather results
		(local.set $qhi)
		(local.set $qlo)
		(local.set $rem)

		;; push to stack
		(call $__stack_dat_push (local.get $rem))
		(call $__stack_dat_push (local.get $qlo))
		(call $__stack_dat_push (local.get $qhi))
	)

	;; https://forth-standard.org/standard/core/AND
	;; ( x1 x2 -- x3 )
	(elem (i32.const 13) $__forth_fn_and)
	(func $__forth_fn_and (type $TypeForthFn)
		(call $__stack_dat_push
			(i32.and (call $__stack_dat_2pop)))
	)

	;; https://forth-standard.org/standard/core/XOR
	;; ( x y -- x^y )
	(elem (i32.const 14) $__forth_fn_xor)
	(func $__forth_fn_xor (type $TypeForthFn)
		(call $__stack_dat_push
			(i32.xor (call $__stack_dat_2pop)))
	)

	;; https://forth-standard.org/standard/core/OR
	;; ( x y -- x|y )
	(elem (i32.const 15) $__forth_fn_or)
	(func $__forth_fn_or (type $TypeForthFn)
		(call $__stack_dat_push
			(i32.or (call $__stack_dat_2pop)))
	)

	;; https://forth-standard.org/proposals/find-name
	;; ( c-addr u -- xt | 0 )
	(elem (i32.const 16) $__forth_fn_find_name)
	(func $__forth_fn_find_name (type $TypeForthFn)
		(local $len i32)
		(local $str i32)

		(local.set $len (call $__stack_dat_pop))
		(local.set $str (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__internal_lookup
				(local.get $str)
				(local.get $len)
				(call $__hash
					(local.get $str)
					(local.get $len))))
	)

	;; https://forth-standard.org/standard/core/PARSE
	;; ( char "ccc<char>" -- c-addr u )
	(elem (i32.const 17) $__forth_fn_parse)
	(func $__forth_fn_parse (type $TypeForthFn)
		(call $__stack_dat_2push
			(call $__internal_parse (call $__stack_dat_pop)))
	)

	;; https://forth-standard.org/standard/core/EXECUTE
	;; ( i * x xt -- j * x )
	(elem (i32.const 18) $__forth_fn_execute)
	(func $__forth_fn_execute (type $TypeForthFn)
		(call $__internal_execute (call $__stack_dat_pop))
	)

	;; https://forth-standard.org/standard/core/COMPILEComma
	;; ( xt -- )
	(elem (i32.const 19) $__forth_fn_compile)
	(func $__forth_fn_compile (type $TypeForthFn)
		(call $__internal_compile (call $__stack_dat_pop))
	)

	;; https://forth-standard.org/standard/exception/THROW
	(elem (i32.const 20) $__forth_fn_throw)
	(func $__forth_fn_throw (type $TypeForthFn)
		(local $err i32)

		(call $__assert
			(i32.eqz (local.tee $err (call $__stack_dat_pop)))
			(local.get $err))
	)

	;; Expose wasmi function for writing to file
	;;
	;; (fd:i32, iovs_ptr:i32, iovs_len:i32, nwritten_ptr:i32) -> errno:i32
	(elem (i32.const 21) $__forth_fn_wasi_fd_write)
	(func $__forth_fn_wasi_fd_write (type $TypeForthFn)
		(local $iovs i32)
		(local $iovs_len i32)
		(local $n_ptr i32)

		(local.set $n_ptr (call $__stack_dat_pop))
		(local.set $iovs_len (call $__stack_dat_pop))
		(local.set $iovs (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__wasi::fd_write
				(call $__stack_dat_pop) ;; fd
				(local.get $iovs)
				(local.get $iovs_len)
				(local.get $n_ptr)))
	)

	;; Expose wasmi for reading from file
	;;
	;; (fd:i32, iovs_ptr:i32, iovs_len:i32, nread_ptr:i32) -> errno:i32
	(elem (i32.const 22) $__forth_fn_wasi_fd_read)
	(func $__forth_fn_wasi_fd_read (type $TypeForthFn)
		(local $iovs i32)
		(local $iovs_len i32)
		(local $n_ptr i32)

		(local.set $n_ptr (call $__stack_dat_pop))
		(local.set $iovs_len (call $__stack_dat_pop))
		(local.set $iovs (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__wasi::fd_read
				(call $__stack_dat_pop) ;; fd
				(local.get $iovs)
				(local.get $iovs_len)
				(local.get $n_ptr)))
	)

	;; Expose wasmi for closing a file
	;;
	;; (fd:i32) -> errno:i32
	(elem (i32.const 23) $__forth_fn_wasi_fd_close)
	(func $__forth_fn_wasi_fd_close (type $TypeForthFn)
		(call $__stack_dat_push
			(call $__wasi::fd_close
				(call $__stack_dat_pop))) ;; fd
	)

	;; Expose wasmi for opening a path
	;;
	;; (dirfd:i32, dirflags:i32, path_ptr:i32, path_len:i32,
	;;  oflags:i32, fs_rights_base:i64, fs_rights_inheriting:i64,
	;;  fdflags:i32, opened_fd_ptr:i32) -> errno:i32
	(elem (i32.const 24) $__forth_fn_wasi_path_open)
	(func $__forth_fn_wasi_path_open (type $TypeForthFn)
		(local $opened_fd_ptr i32)
		(local $fdflags i32)
		(local $fs_rights_inheriting i64)
		(local $fs_rights_base i64)
		(local $oflags i32)
		(local $path_len i32)
		(local $path_ptr i32)
		(local $dirflags i32)

		(local.set $opened_fd_ptr (call $__stack_dat_pop))
		(local.set $fdflags (call $__stack_dat_pop))

		;; NOTE we assume (based on the available flags) that we don't
		;; need the high bit flags for usage in our envionement at this point.
		;; This is certainly the case, we only want "simple" reads/writes, not
		;; yet any more exotic stuff. In the future, we may need to change this
		;; interface if the need arrises
		(local.set $fs_rights_inheriting (i64.extend_i32_u (call $__stack_dat_pop)))
		(local.set $fs_rights_base (i64.extend_i32_u (call $__stack_dat_pop)))

		(local.set $oflags (call $__stack_dat_pop))
		(local.set $path_len (call $__stack_dat_pop))
		(local.set $path_ptr (call $__stack_dat_pop))
		(local.set $dirflags (call $__stack_dat_pop))

		(call $__stack_dat_push
			(call $__wasi::path_open
				(call $__stack_dat_pop) ;; dir_fd
				(local.get $dirflags)
				(local.get $path_ptr)
				(local.get $path_len)
				(local.get $oflags)
				(local.get $fs_rights_base)
				(local.get $fs_rights_inheriting)
				(local.get $fdflags)
				(local.get $opened_fd_ptr)))
	)

	;;
	;; Initialize the native dictionary
	;;
	(func $__dict_init (param $count i32) (result i32)
		(local $idx i32)
		(local $len i32)
		(local $str i32)
		(local $ptr i32)
		(local $hash i32)

		;; allocate a bucket list (1024 hash entries), point to first string
		(local.set $ptr (call $__lookup_new (local.get $count)))
		(local.set $str (global.get $PTR_NATIVE_TEXT))

		;; add native functions to dictionary
		(block $exit (loop $loop

			;; break the loop if we have an empty name
			(br_if $exit
				(i32.eqz (local.tee $len (call $__strlen_z (local.get $str)))))

			;; ensure that we are below exceptions, -8 dictionary overflow
			(call $__assert
				(i32.lt_u
					(i32.add (local.get $str) (i32.add (local.get $len) (i32.const 1)))
					(global.get $PTR_EXCEP_CODE))
				(i32.const -8))

			;; add to dictionary
			(call $__lookup_append
				(local.get $ptr)
				(local.tee $hash
					(call $__hash (local.get $str) (local.get $len)))
				(call $__val_new
					(local.get $str)
					(local.get $len)
					(local.get $hash)
					(local.get $idx)
					(i32.or
						(i32.or
							(global.get $FLG_ASM)
							(global.get $FLG_VISIBLE))
						(i32.and
							(global.get $FLG_IMMEDIATE)
							(i32.load8_u
								(i32.add
									(local.get $str)
									(i32.add (local.get $len) (i32.const 1))))))))

			;; point to the next function & string (ensuring \0 terminator & flag)
			(local.set $idx (i32.add (local.get $idx) (i32.const 1)))
			(local.set $str (i32.add (local.get $str) (i32.add (local.get $len) (i32.const 2))))

			;; continue with the next
			br $loop))

		;; return dict pointer
		local.get $ptr
	)
