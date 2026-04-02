
(;

	forth/internal.wat

	Forth words that are exposed, but are quite large (logic-wise) and
	cannot and should not be inlined into builtins. Additionally these
	are used to implement the parser and interpreter itself.

;)

	;; execution & compilation variables
	(global $exec_list      (mut i32) (i32.const 0))
	(global $exec_ptr_nt    (mut i32) (i32.const 0))
	(global $dict_exit_ptr  (mut i32) (i32.const 0))

	;;
	;; Internal functions. These implement FORTH words, but do so on the
	;; WASM stack. From a builtin words implementation perspective, these
	;; will be called and converted to the FORTH stack.
	;;

	;;
	;; Starts the dictionary header for a new word
	;;
	(func $__internal_builds (param $name i32) (param $len i32)
		(local $hash i32)
		(local $s i32)
		(local $list i32)

		;; -19 definition name too long
		(call $__assert (i32.le_u (local.get $len) (i32.const 48)) (i32.const -19))

		;; zero name or len?
		(i32.or
			(i32.eqz (local.get $name))
			(i32.eqz (local.get $len))) (if

			;; something empty, no hash
			(then)

			;; we have data, hash it, copy name to new buffer
			(else
				(local.set $name (call $__strdup_n (local.get $name) (local.get $len)))
				(local.set $hash (call $__hash (local.get $name) (local.get $len)))))

		;; create a hidden definition for this word (w/ non-transient string)
		(i32.store
			(global.get $PTR_PTR_TOK_CMP)
			(call $__val_new
				(local.get $name)
				(local.get $len)
				(local.get $hash)
				(local.tee $list (call $__list_new))
				(global.get $FLG_TKN)))

		;; set the row/col value
		(local.set $s (call $__src_frame_peek))
		(call $__list_set_file
			(local.get $list)
			(local.get $s)
			(call $__src_get_row (local.get $s))
			(i32.sub (call $__line_get_off) (local.get $len)))

		;; set the owner for the list
		(call $__list_set_owner
			(local.get $list)
			(i32.load (global.get $PTR_PTR_TOK_CMP)))

		;; add an exit token
		(call $__list_append
			(local.get $list)
			(call $__val_dup (global.get $dict_exit_ptr)))

		;; hash?
		(local.get $hash) (if

			;; hash, add to dictionary
			(then
				(call $__lookup_append
					(i32.load (global.get $PTR_WID_CURR))
					(local.get $hash)
					(i32.load (global.get $PTR_PTR_TOK_CMP))))

			;; skip it
			(else))
	)

	;;
	;; Ends the definition of a new word via ;
	;;
	;; https://forth-standard.org/standard/core/Semi
	;;
	(func $__internal_compile_end
		(local $list i32)

		;; check for compilation state, -29 compiler nesting
		(call $__assert (i32.load (global.get $PTR_STATE)) (i32.const -29))

		;; make visible
		(call $__val_set_flags
			(i32.load (global.get $PTR_PTR_TOK_CMP))
			(i32.or
				(global.get $FLG_VISIBLE)
				(call $__val_get_flags (i32.load (global.get $PTR_PTR_TOK_CMP)))))

		;; change to interpret state
		(i32.store (global.get $PTR_STATE) (i32.const 0))
	)

	;;
	;; Jump to a new execution location
	;;
	(func $__internal_next (param $ptr_to i32)
		;; set jump location
		(i32.store (global.get $PTR_PTR_TOK_NXT) (local.get $ptr_to))
	)

	;;
	;; Handle exit, unwinds a call
	;;
	;; https://forth-standard.org/standard/core/EXIT
	;;
	(func $__internal_exit
		;; restore next jump location
		(call $__internal_next (call $__stack_ret_pop))
	)

	;;
	;; Call to a new execution location
	;;
	(func $__internal_call (param $ptr_to i32)
		;; store return location (can be 0 for outermost call)
		(call $__stack_ret_push (i32.load (global.get $PTR_PTR_TOK_NXT)))

		;; set jump location
		(call $__internal_next (local.get $ptr_to))
	)

	(func $__internal_execute_does (param $val i32) (param $flg i32)
		(local $next i32)

		;; exec?
		(call $__has_flag
			(local.get $flg)
			(global.get $FLG_VARIANT)) (if

			;; execute the jump below
			(then)

			;; mark the jump, replace behaviour
			(else
				;; first token is hard-coded DFA via create, replace second
				(call $__val_fill
					(call $__val_get_value
						(call $__ent_get_next
							(call $__list_get_head
								(call $__val_get_value
									(i32.load (global.get $PTR_PTR_TOK_CMP))))))
					(global.get $PTR_DO_EXEC_TEXT)
					(call $__strlen_z (global.get $PTR_DO_EXEC_TEXT))
					(i32.const 0)
					(local.get $val)
					(i32.or (global.get $FLG_DOES) (global.get $FLG_VARIANT)))

				;; Find the real exit - since we override the end token list
				;; via does, we cannot just grab the last
				(block $exit (loop $loop
					(br_if $exit
						(i32.eqz (local.tee $next (call $__ent_get_next (local.get $val)))))

					(local.set $val (local.get $next))
					(br $loop)))))

		;; excute the jump
		(call $__internal_next (local.get $val))
	)

	(func $__internal_execute_literal (param $val i32) (param $flg i32)
		;; store the i32
		(call $__stack_dat_push (local.get $val))

		;; double value?
		(call $__has_flag
			(local.get $flg)
			(global.get $FLG_VARIANT)) (if

			;; double, push hi=0 on positive, hi=-1 on negative
			(then
				(call $__stack_dat_push
					(select
						;; negative
						(i32.const -1)
						;; positive
						(i32.const 0)
						;; negative?
						(i32.lt_s (local.get $val) (i32.const 0)))))

			;; single literal, do nothing additional
			(else))
	)

	(func $__internal_execute_local (param $xt i32) (param $idx i32)
		;; retrieve value, push it
		(call $__stack_dat_push (call $__stack_loc_peek_at (local.get $idx)))
	)

	(func $__internal_execute_list (param $val i32)
		;; store execution list, jump to head
		(global.set $exec_list (local.get $val))
		(call $__internal_call (call $__list_get_head (local.get $val)))
	)

	;;
	;; Execute native builtin by direct index dispatch.
	;;
	m4_include(<!build/w4-exec-asm.wat!>)

	;;
	;; Execute a word based on the embedded flags (raw/exposed path).
	;; This is the implementation exposed via builtin `(execute)`.
	;;
	(func $__internal_execute_exposed (param $ptr_xt i32)
		(local $fcl i32)
		(local $flg i32)
		(local $val i32)

		;; ensure a valid pointer
		(call $__assert_ptr (local.get $ptr_xt))

		;; store current executing
		(i32.store (global.get $PTR_PTR_TOK_EXE) (local.get $ptr_xt))

		;; retrieve item value & flag
		(local.set $val (call $__val_get_value (local.get $ptr_xt)))
		(local.set $flg (call $__val_get_flags (local.get $ptr_xt)))
		(local.set $fcl
			(i32.and
				(local.get $flg)
				(i32.const -16)))

		;; check for native functions
		(i32.eq
			(local.get $fcl)
			(global.get $FLG_ASM)) (if

			;; native, call directly
			(then (call $__internal_execute_asm (local.get $val)))

			;; non-native, check tokens
			(else
				(i32.eq
					(local.get $fcl)
					(global.get $FLG_TKN)) (if

					;; token list, jump to it
					(then (call $__internal_execute_list (local.get $val)))

					;; non-tokens, check literals
					(else
						(i32.eq
							(local.get $fcl)
							(global.get $FLG_LIT)) (if

							;; literals
							(then (call $__internal_execute_literal (local.get $val) (local.get $flg)))

							;; not literals, check does
							(else
								(i32.eq
									(local.get $fcl)
									(global.get $FLG_DOES)) (if

									;; does marker, check for execution
									(then (call $__internal_execute_does (local.get $val) (local.get $flg)))

									;; not does, check locals
									(else
										(i32.eq
											(local.get $fcl)
											(global.get $FLG_LOCAL)) (if

										;; local
										(then (call $__internal_execute_local (local.get $ptr_xt) (local.get $val)))

										;; unknown, -12 argument type mismatch
										(else (call $__assert (i32.const 0) (i32.const -12))))))))))))
	)

	;;
	;; Lookup the Forth-side `execute` word. Returns nt|0.
	;; Cache the nt once found to avoid repeated dictionary lookups.
	;;
	(func $__internal_lookup_execute_nt (result i32)
		(local $ptr_nt i32)

		;; not cached? lookup once and cache if found
		(i32.eqz (local.tee $ptr_nt (global.get $exec_ptr_nt))) (if
			(then
				(global.set $exec_ptr_nt (local.tee $ptr_nt
					(call $__internal_lookup
						(global.get $PTR_EXEC_TEXT)
						(i32.const 7)
						(call $__hash
							(global.get $PTR_EXEC_TEXT)
							(i32.const 7)))))))

		local.get $ptr_nt
	)

	;;
	;; Wrapped execute path: if Forth `execute` exists, route through it;
	;; otherwise execute directly via the exposed/raw implementation.
	;;
	(func $__internal_execute (param $ptr_xt i32)
		(local $fcl i32)
		(local $ptr_exec_nt i32)
		(local $ptr_exec_xt i32)

		(local.set $fcl
			(i32.and
				(call $__val_get_flags (local.get $ptr_xt))
				(i32.const -16)))

		;; never route ASM through Forth `execute` to avoid recursion on `(execute)`
		(i32.eq
			(local.get $fcl)
			(global.get $FLG_ASM)) (if
			(then
				(call $__internal_execute_exposed (local.get $ptr_xt))
				return)
			(else))

		(local.set $ptr_exec_nt (call $__internal_lookup_execute_nt))

		(local.get $ptr_exec_nt) (if

			;; route through Forth `execute`
			(then
				(local.set $ptr_exec_xt (call $__val_get_value (local.get $ptr_exec_nt)))
				(i32.ne (local.get $ptr_exec_xt) (local.get $ptr_xt)) (if
					(then
						(call $__stack_dat_push (local.get $ptr_xt))
						(call $__internal_execute_exposed (local.get $ptr_exec_xt)))
					(else
						(call $__internal_execute_exposed (local.get $ptr_xt)))))

			;; fallback to raw/exposed direct path
			(else
				(call $__internal_execute_exposed (local.get $ptr_xt))))
	)

	;;
	;; Compiles a word
	;;
	;; https://forth-standard.org/standard/core/COMPILEComma
	;;
	(func $__internal_compile (param $ptr_xt i32)
		;; ensure it is a valid pointer
		(call $__assert_ptr (local.get $ptr_xt))

		;; store current executing token
		(i32.store (global.get $PTR_PTR_TOK_EXE) (local.get $ptr_xt))

		;; ensure we have valid flags, -13 undefined word
		(call $__assert
			(call $__has_flag
				(call $__val_get_flags (local.get $ptr_xt))
				(global.get $FLG_ANY))
			(i32.const -13))

		;; compile it, adding it to the current list
		(call $__toks_insert (local.get $ptr_xt))
	)

	;;
	;; Executes exec_next until all values are consumed
	;;
	(func $__internal_run
		(local $ptr_xt i32)

		;; loop while we have tokens, we have from parsing (single), but could
		;; also get them from the return stack, i.e. when we have executed
		(block $exit (loop $loop

			;; exit if we don't have a next xt
			(br_if $exit
				(i32.eqz (local.tee $ptr_xt
					(call $__val_get_value (i32.load (global.get $PTR_PTR_TOK_NXT))))))

			;; jump to next
			(call $__internal_next (call $__ent_get_next (i32.load (global.get $PTR_PTR_TOK_NXT))))

			;; execute current via exposed/raw token path
			(call $__internal_execute_exposed (local.get $ptr_xt))

			;; continue with next (if non-zero)
			(br $loop)))
	)

	;;
	;; Find a word in the dictionary(ies)
	;;
	(func $__internal_lookup (param $str i32) (param $len i32) (param $hash i32) (result i32)
		(local $lwid i32)
		(local $idx i32)
		(local $num i32)
		(local $ptr i32)
		(local $xt i32)

		;; get the number of wids
		(local.set $num (i32.load (global.get $PTR_WID_COUNT)))
		(local.set $ptr (i32.load (global.get $PTR_PTR_WID_LIST)))

		;; local wid?
		(local.tee $lwid (i32.load (global.get $PTR_LOC_WID))) (if

			;; lookup in locals wid
			(then
				(local.set $xt
					(call $__lookup_find
						(local.get $lwid)
						(local.get $str)
						(local.get $len)
						(local.get $hash))))

			;; no, continue below
			(else))

		;; lookup until found or no next
		(block $exit (loop $loop
			;; exit if xt found or no more lists
			(br_if $exit
				(i32.or
					(local.get $xt)
					(i32.eq (local.get $idx) (local.get $num))))

			;; get xt
			(local.set $xt
				(call $__lookup_find
					(i32.load (local.get $ptr))
					(local.get $str)
					(local.get $len)
					(local.get $hash)))

			;; move to next entry
			(local.set $idx (i32.add (local.get $idx) (i32.const 1)))
			(local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))

			;; continue loop
			(br $loop)))

		;; return it
		local.get $xt
	)

	;;
	;; Interprets the current line (as called from evaluate/quit)
	;;
	;; https://forth-standard.org/standard/core/QUIT
	;;
	(func $__internal_interpret
		(local $wlen i32)
		(local $wptr i32)
		(local $xt_val i32)
		(local $xt_flg i32)
		(local $xt_imm i32)
		(local $ptr_xt i32)

		(block $exit (loop $loop

			;; get the next word
			(call $__internal_parse (i32.const 32))
			local.set $wlen
			local.set $wptr

			;; exit if we have an empty word
			(br_if $exit
				(i32.eqz (local.get $wlen)))

			;; find it (nt|0 -> name>xt|0)
			(local.tee $ptr_xt
				(call $__val_get_value
					(call $__internal_lookup
						(local.get $wptr)
						(local.get $wlen)
						(call $__hash
							(local.get $wptr)
							(local.get $wlen))))) (if

				;; found it
				(then
					;; extract immediate flag for execution below
					(local.set $xt_imm
						(call $__has_flag
							(call $__val_get_flags (local.get $ptr_xt))
							(global.get $FLG_IMMEDIATE))))

				;; try to create literal
				(else
					;; set the immediate flag to false (execute below)
					(local.set $xt_imm (i32.const 0))

					;; parse it as a literal
					(call $__str_to_num (local.get $wptr) (local.get $wlen) (call $__get_base))
					local.set $xt_flg
					local.set $xt_val

					;; executing & valid literal?
					(i32.and
						(i32.eqz (i32.load (global.get $PTR_STATE)))
						(call $__has_flag
							(local.get $xt_flg)
							(global.get $FLG_LIT))) (if

					;; interpret state literal → push directly and continue
					(then
						(call $__internal_execute_literal
							(local.get $xt_val)
							(local.get $xt_flg))
						br $loop)

					;; either compiling or invalid
					(else
						;; store token already (need it for assert debug trace)
						(i32.store
							(global.get $PTR_PTR_TOK_EXE)
							(local.tee $ptr_xt
								(call $__val_new
									;; no ptr/len for lits
									(local.get $xt_flg) (if (result i32 i32)
										;; literal, drop string
										(then (i32.const 0) (i32.const 0))
										;; unknown, will error below
										(else (local.get $wptr) (local.get $wlen)))
									(i32.const 0)
									(local.get $xt_val)
									(local.get $xt_flg))))

						;; should have a non-zero flag, -13 undefined word
						(call $__assert (local.get $xt_flg) (i32.const -13))))))

				;; execute (immediate or state=0) or compile
				(i32.and
					(i32.eqz (local.get $xt_imm))
					(i32.load (global.get $PTR_STATE))) (if

					;; compile it
					(then (call $__internal_compile (local.get $ptr_xt)))

					;; execute it
					(else
						(call $__internal_execute (local.get $ptr_xt))
						(call $__internal_run)))

			;; continue to next
			br $loop))
	)

	;;
	;; Evaluates the input data, set the code and initial values for an
	;; interpret loop.
	;;
	;; https://forth-standard.org/standard/core/EVALUATE
	;;
	(func $__internal_evaluate (export "evaluate") (param $code_ptr i32) (param $code_len i32)
		(local $s i32)
		(local $orig_s i32)

		;; create structure
		(local.set $s (call $__alloc (global.get $SIZEOF_SRC)))

		;; store base info
		(call $__src_set_ln_ptr (local.get $s) (local.get $code_ptr))
		(call $__src_set_ln_len (local.get $s) (local.get $code_len))

		;; save caller frame pointer (0 if none)
		(local.set $orig_s (call $__src_frame_peek))

		;; enter frame
		(call $__src_push_frame (local.get $s))
		(call $__line_set (local.get $s))

		;; loop while we have source
		(block $exit (loop $loop

			;; valid iov with characters?
			(i32.and
				(i32.ne (call $__line_get_iov) (i32.const 0))
				(i32.lt_u
					(call $__line_get_off)
					(call $__iov_get_len (call $__src_get_ln_iov (local.get $s))))) (if

				;; valid, interpret below
				(then)

				;; no iov, no refill
				(else (br $exit)))

			;; interpret & continue with loop
			(call $__internal_interpret)
			(br $loop)))

		;; leave frame (normal exit)
		(call $__src_pop_frame)

		;; re-bind caller SOURCE so we do NOT trigger a refill
		(local.get $orig_s) (if

			;; rebind
			(then (call $__line_set (local.get $orig_s)))

			;; no caller, skip
			(else))
	)

	;;
	;; Parse a word delimited by the passed character
	;;
	;; https://forth-standard.org/standard/core/PARSE
	;;
	;; This is non-standard and therefore exposed as parse-token.
	;; The implementation here always skips leading whitespace.
	;;
	(func $__internal_parse (param $delim i32) (result i32 i32)
		(local $idx i32)
		(local $start i32)
		(local $end i32)
		(local $str i32)
		(local $len i32)
		(local $ch i32)
		(local $is_eol i32)
		(local $iov i32)

		;; phase 1: validate current source iov
		(local.set $iov (call $__line_get_iov))
		(i32.or
			(i32.eqz (local.get $iov))
			(i32.ge_u (local.get $iov) (i32.load (global.get $PTR_ALLOC)))) (if
			(then
				(return (i32.const 0) (i32.const 0)))
			(else))

		;; phase 2: load source span and current parse offset (>in)
		(call $__iov_get_str_len (local.get $iov))
		local.set $len
		local.set $str
		(local.set $idx (call $__line_get_off))

		;; phase 3: skip leading separators (eow)
		(block $skip_done (loop $skip
			(br_if $skip_done
				(i32.ge_u (local.get $idx) (local.get $len)))

			(local.set $ch
				(i32.load8_u
					(i32.add (local.get $str) (local.get $idx))))
			(local.set $is_eol
				(i32.or
					(i32.eq (local.get $ch) (i32.const 10))
					(i32.or
						(i32.eqz (local.get $ch))
						(i32.eq (local.get $ch) (i32.const 4)))))

			;; stop skipping once non-eow is reached
			(br_if $skip_done
				(i32.eqz
					(i32.or
						(local.get $is_eol)
						(i32.le_u (local.get $ch) (i32.const 32)))))

			(local.set $idx (i32.add (local.get $idx) (i32.const 1)))
			(br $skip)))

		;; no token left after leading-separator skip
		(i32.ge_u (local.get $idx) (local.get $len)) (if
			(then
				(call $__line_set_off (local.get $idx))
				(return (i32.const 0) (i32.const 0)))
			(else))

		(local.set $start (local.get $idx))

		;; phase 4: scan token body according to delimiter mode
		;; delim = BL => stop on eow
		(i32.eq (local.get $delim) (i32.const 32)) (if
			(then
				(block $scan_done (loop $scan
					(br_if $scan_done
						(i32.ge_u (local.get $idx) (local.get $len)))

					(local.set $ch
						(i32.load8_u
							(i32.add (local.get $str) (local.get $idx))))
					(local.set $is_eol
						(i32.or
							(i32.eq (local.get $ch) (i32.const 10))
							(i32.or
								(i32.eqz (local.get $ch))
								(i32.eq (local.get $ch) (i32.const 4)))))

					(br_if $scan_done
						(i32.or
							(local.get $is_eol)
							(i32.le_u (local.get $ch) (i32.const 32))))

					(local.set $idx (i32.add (local.get $idx) (i32.const 1)))
					(br $scan))))
			;; delim = 0 => stop on eol
			(else
				(i32.eqz (local.get $delim)) (if
					(then
						(block $scan_done (loop $scan
							(br_if $scan_done
								(i32.ge_u (local.get $idx) (local.get $len)))

							(local.set $ch
								(i32.load8_u
									(i32.add (local.get $str) (local.get $idx))))
							(local.set $is_eol
								(i32.or
									(i32.eq (local.get $ch) (i32.const 10))
									(i32.or
										(i32.eqz (local.get $ch))
										(i32.eq (local.get $ch) (i32.const 4)))))

							(br_if $scan_done (local.get $is_eol))
							(local.set $idx (i32.add (local.get $idx) (i32.const 1)))
							(br $scan))))
					;; generic delimiter (direct char match)
					(else
						(block $scan_done (loop $scan
							(br_if $scan_done
								(i32.ge_u (local.get $idx) (local.get $len)))

							(local.set $ch
								(i32.load8_u
									(i32.add (local.get $str) (local.get $idx))))
							(br_if $scan_done
								(i32.eq (local.get $ch) (local.get $delim)))

								(local.set $idx (i32.add (local.get $idx) (i32.const 1)))
								(br $scan)))))))

		(local.set $end (local.get $idx))

		;; phase 5: consume one delimiter/eol when present
		(i32.lt_u (local.get $idx) (local.get $len)) (if
			(then (local.set $idx (i32.add (local.get $idx) (i32.const 1))))
			(else))

		(call $__line_set_off (local.get $idx))

		;; phase 6: return transient slice and length
		;; NOTE The string here is transient - callers should ensure that they
		;; have their own copy (and it should be copied for forth inside builtins)
		(i32.add (local.get $str) (local.get $start))
		(i32.sub (local.get $end) (local.get $start))
	)
