
(;

	forth/internal.wat

	Forth words that are exposed, but are quite large (logic-wise) and
	cannot and should not be inlined into builtins. Additionally these
	are used to implement the parser and interpreter itself.

;)

	;; parsing variables
	(global $parse_code_ptr (mut i32) (i32.const 0))
	(global $parse_code_len (mut i32) (i32.const 0))
	(global $parse_code_idx (mut i32) (i32.const 0))
	(global $parse_code_row (mut i32) (i32.const 0))
	(global $parse_frame	(mut i32) (i32.const 0))
	(global $parse_iov_ptr  (mut i32) (i32.const 0))

	;; execution & compilation variables
	(global $exec_list      (mut i32) (i32.const 0))
	(global $exec_next      (mut i32) (i32.const 0))
	(global $dict_exit_ptr  (mut i32) (i32.const 0))
	(global $xt_comp		(mut i32) (i32.const 0)) ;; PTR_PTR_TOK_CMP
	(global $xt_exec		(mut i32) (i32.const 0)) ;; PTR_PTR_TOK_EXE
	(global $stack_dat		(mut i32) (i32.const 0))
	(global $stack_ret		(mut i32) (i32.const 0))
	(global $stack_ctl		(mut i32) (i32.const 0))
	(global $stack_src		(mut i32) (i32.const 0))
	(global $local_frame    (mut i32) (i32.const 0))
	(global $local_value    (mut i32) (i32.const 0))
	(global $list_toks      (mut i32) (i32.const 0))

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
		(global.set $list_toks (call $__list_new))
		(global.set $xt_comp
			(call $__store
				(global.get $PTR_PTR_TOK_CMP)
				(call $__val_new
					(local.get $name)
					(local.get $len)
					(local.get $hash)
					(global.get $list_toks)
					(global.get $FLG_TKN))))

		;; set the row/col value
		(call $__list_set_file
			(global.get $list_toks)
			(global.get $parse_frame)
			(global.get $parse_code_row)
			(i32.sub (call $__line_get_off) (local.get $len)))

		;; set the owner for the list
		(call $__list_set_owner
			(global.get $list_toks)
			(global.get $xt_comp))

		;; add an exit token
		(call $__list_append
			(global.get $list_toks)
			(call $__val_dup (global.get $dict_exit_ptr)))

		;; hash?
		(local.get $hash) (if

			;; hash, add to dictionary
			(then
				(call $__lookup_append
					(i32.load (global.get $PTR_WID_CURR))
					(local.get $hash)
					(global.get $xt_comp)))

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

		;; reset wid for locals
		(i32.store (global.get $PTR_LOC_WID) (i32.const 0))

		;; make visible
		(call $__val_set_flags
			(global.get $xt_comp)
			(i32.or
				(global.get $FLG_VISIBLE)
				(call $__val_get_flags (global.get $xt_comp))))

	m4_ifdef(`DEBUG', `
		;; DEBUG, output the token name and definition
		(call $__iov_emit_chr_stdout (i32.const 10))
		(call $__iov_emit_chr_stdout (i32.const 10))
		(call $__iov_emit_chr_stdout (i32.const 59)) ;; semi

		(call $__iov_emit_chr_stdout (i32.const 32))
		(call $__iov_emit_stdout (global.get $xt_comp))
		(call $__iov_emit_chr_stdout (i32.const 32))
		(call $__DEBUG_emit_num (global.get $xt_comp) (i32.const 16))
		(call $__iov_emit_chr_stdout (i32.const 32))
		(call $__DEBUG_emit_num (call $__val_get_flags (global.get $xt_comp)) (i32.const 16))
		(call $__iov_emit_chr_stdout (i32.const 32))
		(call $__iov_emit_chr_stdout (i32.const 10))

		(call $__iov_emit_chr_stdout (i32.const 10))
		(call $__DEBUG_emit_list (call $__val_get_value (global.get $xt_comp)))
	')

		;; change to interpret state
		(i32.store (global.get $PTR_STATE) (i32.const 0))
	)

	;;
	;; Handle exit, unwinds a jump
	;;
	;; https://forth-standard.org/standard/core/EXIT
	;;
	(func $__internal_exit
		;; FIXME Would prefer if we can just _always_ pop, instead
		;; of peeking if we have data... exit should be clean
		;;
		;; (global.set $exec_next (call $__stack_ret_pop))

		;; set instruction pointer
		(global.set $exec_next

			;; value on return stack?
			(call $__stack_ret_count) (if (result i32)

				;; pop pointer
				(then (call $__stack_ret_pop))

				;; zero pointer
				(else (i32.const 0))))
	)

	;;
	;; Call to a new execution location
	;;
	(func $__internal_call (param $ptr_to i32)
		;; global next available?
		(global.get $exec_next) (if

			;; store return location
			(then (call $__stack_ret_push (global.get $exec_next)))

			(else))

		;; set jump location
		(call $__internal_jump (local.get $ptr_to))
	)

	;;
	;; Jump to a new execution location
	;;
	(func $__internal_jump (param $ptr_to i32)
		;; set jump location
		(global.set $exec_next (local.get $ptr_to))
	)

	;;
	;; Handle does via storing the address for the specific location
	;;
	;; https://forth-standard.org/standard/core/DOES
	;;
	(func $__internal_does
		(local $ptr_xt i32)

		;; setup the jump location for inclusion (temp -1 value, replaced below)
		(call $__toks_insert
			(local.tee $ptr_xt
				(call $__val_new
					(global.get $PTR_DO_MARK_TEXT)
					(call $__strlen_z (global.get $PTR_DO_MARK_TEXT))
					(i32.const 0)
					(i32.const -1)
					(global.get $FLG_DO_MARK))))

		;; update the address to inserted PTR_DO_MARK_TEXT (located at list tail)
		(call $__val_set_value
			(local.get $ptr_xt)
			(call $__list_get_tail
				(call $__val_get_value (global.get $xt_comp))))
	)

	(func $__internal_execute_does (param $val i32) (param $flg i32)
		(local $rep i32)

		;; exec?
		(call $__has_flag
			(local.get $flg)
			(global.get $FLG_DO_EXEC)) (if

			;; execute the jump
			(then (call $__internal_jump (local.get $val)))

			;; mark the jump, replace behaviour
			(else
				;; first token is hard-coded DFA via create, replace second
				(call $__val_fill
					(call $__val_get_value
						(call $__ent_get_next
							(call $__list_get_head (global.get $list_toks))))
					(global.get $PTR_DO_EXEC_TEXT)
					(call $__strlen_z (global.get $PTR_DO_EXEC_TEXT))
					(i32.const 0)
					(local.get $val)
					(global.get $FLG_DO_EXEC))

				;; skip remainder, no return
				(global.set $exec_next (i32.const 0))))
	)

	(func $__internal_execute_literal (param $val i32) (param $flg i32)
		;; store the i32
		(call $__stack_dat_push (local.get $val))

		;; double value?
		(call $__has_flag
			(local.get $flg)
			(global.get $FLG_LITD)) (if

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

	(func $__internal_execute_list (param $val i32)
		;; store execution list, jump to head
		(global.set $exec_list (local.get $val))
		(call $__internal_call (call $__list_get_head (local.get $val)))
	)

	;;
	;; Execute a word based on the embedded flags
	;;
	;; https://forth-standard.org/standard/core/EXECUTE
	;;
	(func $__internal_execute (param $ptr_xt i32)
		(local $flg i32)
		(local $val i32)

		;; ensure a valid pointer
		(call $__assert_ptr (local.get $ptr_xt))

		;; store current executing
		(global.set $xt_exec
			(call $__store (global.get $PTR_PTR_TOK_EXE) (local.get $ptr_xt)))

		;; retrieve item value & flag
		(local.set $val (call $__val_get_value (local.get $ptr_xt)))
		(local.set $flg (call $__val_get_flags (local.get $ptr_xt)))

		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '
		;; (call $__iov_emit_chr_stdout (i32.const 88)) ;; 'X'
		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '
		;; (call $__iov_emit_stdout (local.get $ptr_xt))

		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '
		;; (call $__DEBUG_emit_num (i32.load (global.get $PTR_STATE)) (i32.const 10))

		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '
		;; (call $__DEBUG_emit_num (local.get $ptr_xt) (i32.const 16))
		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '
		;; (call $__DEBUG_emit_num (local.get $flg) (i32.const 16))
		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '
		;; (call $__DEBUG_emit_num (local.get $val) (i32.const 16))
		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '

		;; (i32.and
		;; 	(call $__has_flag
		;; 		(local.get $flg)
		;; 		(global.get $FLG_ASM))
		;; 	(i32.eqz (local.get $val))) (if

		;; 	;; exit, show stack before as-is
		;; 	(then
		;; 		(call $__iov_emit_chr_stderr (i32.const 10)) ;; \n
		;; 		(call $__DEBUG_emit_stack (global.get $stack_dat))
		;; 		(call $__iov_emit_chr_stderr (i32.const 10)) ;; \n
		;; 		(call $__DEBUG_emit_stack (global.get $stack_ret))
		;; 		;; (call $__iov_emit_chr_stderr (i32.const 10)) ;; \n
		;; 		;; (call $__DEBUG_emit_stack (global.get $stack_ctl))
		;; 		;; (call $__iov_emit_chr_stderr (i32.const 10)) ;; \n
		;; 	))

		;; check for native functions
		(call $__has_flag
			(local.get $flg)
			(global.get $FLG_ASM)) (if

			;; native, call directly
			(then (call_indirect (type $TypeForthFn) (local.get $val)))

			;; non-native, check tokens
			(else
				(call $__has_flag
					(local.get $flg)
					(global.get $FLG_TKN)) (if

					;; token list, jump to it
					(then (call $__internal_execute_list (local.get $val)))

					;; non-tokens, check literals
					(else
						(call $__has_flag
							(local.get $flg)
							(global.get $FLG_LIT)) (if

							;; literals
							(then (call $__internal_execute_literal (local.get $val) (local.get $flg)))

							;; not literals, check does
							(else
								(call $__has_flag
									(local.get $flg)
									(global.get $FLG_DO_MARK)) (if

									;; does marker, check for execution
									(then (call $__internal_execute_does (local.get $val) (local.get $flg)))

									;; unknown, -12 argument type mismatch
									(else (call $__assert (i32.const 0) (i32.const -12))))))))))
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
		(global.set $xt_exec
			(call $__store (global.get $PTR_PTR_TOK_EXE) (local.get $ptr_xt)))

		;; ensure we have valid flags, -13 undefined word
		(call $__assert
			(call $__has_flag
				(call $__val_get_flags (local.get $ptr_xt))
				(global.get $FLG_ANY))
			(i32.const -13))

		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '
		;; (call $__iov_emit_chr_stdout (i32.const 67)) ;; 'C'
		;; (call $__iov_emit_chr_stdout (i32.const 32)) ;; ' '
		;; (call $__iov_emit_stdout (local.get $ptr_xt))

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
					(call $__val_get_value (global.get $exec_next)))))

			;; set next instruction pointer
			(global.set $exec_next (call $__ent_get_next (global.get $exec_next)))

			;; execute current
			(call $__internal_execute (local.get $ptr_xt))

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
						(global.set $xt_exec
							(local.tee $ptr_xt
								(call $__store
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
											(local.get $xt_flg))))))

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

		;; create structure
		(local.set $s (call $__alloc (global.get $SIZEOF_SRC)))

		;; store base info
		(call $__src_set_kind (local.get $s) (global.get $SRC_KIND_MEM))
		(call $__src_set_ptr (local.get $s) (local.get $code_ptr))
		(call $__src_set_len (local.get $s) (local.get $code_len))
		(call $__src_set_ln_iov (local.get $s) (call $__alloc (global.get $SIZEOF_IOV)))

		;; evaluate the source
		(call $__internal_evaluate_frame (local.get $s))
	)

	;;
	;; Runs the evaulation loop over a source
	;;
	(func $__internal_evaluate_frame (param $s i32)
		(local $caller_s i32)

		;; save caller frame pointer (0 if none)
		(local.set $caller_s (global.get $parse_frame))

		;; enter frame
		(call $__src_push_frame (local.get $s))

		;; loop while we have source
		(block $exit (loop $loop

			;; valid iov with characters?
			(i32.and
				(i32.ne (call $__line_get_iov) (i32.const 0))
				(i32.lt_u
					(call $__line_get_off)
					(call $__iov_get_len (global.get $parse_iov_ptr)))) (if

				;; valid, interpret below
				(then)

				;; no iov, try refill
				(else
					(br_if $exit
						(i32.eqz (call $__internal_refill)))))

			;; interpret & continue with loop
			(call $__internal_interpret)
			(br $loop)))

		;; leave frame (normal exit)
		(call $__src_pop_frame)

		;; re-bind caller SOURCE so we do NOT trigger a refill
		(local.get $caller_s) (if
			(then
				(call $__line_set
				(call $__src_get_ln_iov (local.get $caller_s))
				(call $__src_get_ln_off_ptr (local.get $caller_s))))
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
		(local $idx_curr i32)
		(local $idx_find i32)
		(local $str i32)
		(local $len i32)
		(local $ch i32)
		(local $is_eow i32)
		(local $is_len i32)

		(block $exit

			;; check for iov, needs to be non-zero and in-range
			(br_if $exit
				(i32.or
					(i32.eqz (call $__line_get_iov))
					(i32.ge_u
						(call $__line_get_iov)
						(i32.load (global.get $PTR_ALLOC)))))

			;; load the current index from >in, set invalid find idx
			(local.set $idx_curr (call $__line_get_off))
			(local.set $idx_find (i32.const -1))

			;; load the iov and extract src, len
			(call $__iov_get_str_len (call $__line_get_iov))
			local.set $len
			local.set $str

			;; parse the line until delim (or eol)
			(loop $loop

				;; exit if we have exhausted the string
				(br_if $exit
					(i32.ge_u (local.get $idx_curr) (local.get $len)))

				;; get the character and check for eow
				(i32.and
					(i32.eqz (local.tee $is_eow
						(call $__ch_is_eow (local.tee $ch
							(i32.load8_u (i32.add (local.get $str) (local.get $idx_curr)))))))
					(i32.eq
						(local.get $idx_find)
						(i32.const -1))) (if

					;; set index now
					(then (local.set $idx_find (local.get $idx_curr)))

					;; continue
					(else))

				;; increment index & >in (done after leading whitespace check)
				(call $__line_set_off
					(local.tee $idx_curr (i32.add (local.get $idx_curr) (i32.const 1))))

				;; expand eow checks for 32 and 0 lookups
				(local.set $is_eow
					(i32.or
						;; space, all eow characters
						(i32.and
							(i32.eq (local.get $delim) (i32.const 32))
							(i32.ne (local.get $is_eow) (i32.const 0)))
						;; 0, all eol characters
						(i32.and
							(i32.eqz (local.get $delim))
							(i32.ne (call $__ch_is_eol (local.get $ch)) (i32.const 0)))))

				;; do we have a starting index?
				(i32.ne
					(local.get $idx_find)
					(i32.const -1)) (if

					;; starting index, check for matches, direct, eow or eol
					(then
						(i32.or
							;; direct match
							(i32.eq (local.get $ch) (local.get $delim))
							;; end of data stream
							(i32.or
								;; eow and eol checks
								(local.get $is_eow)
								;; exhausted checks
								(local.tee $is_len
									(i32.and
										;; line was exhausted
										(i32.eq (local.get $idx_curr) (local.get $len))
										;; no eow flag and needs either eow or eol
										(i32.and
											(i32.eqz (local.get $is_eow))
											(i32.or
												(i32.eq (local.get $delim) (i32.const 32))
												(i32.eqz (local.get $delim)))))))) (if

							;; match found, return (ptr, len)
							(then
								;; set length now (too messy to inline below, possible as-is into
								;; the alloc, which works, but it has no readability at all)
								(local.set $len
									(i32.sub
										(i32.sub (local.get $idx_curr) (local.get $idx_find))
										(select
											;; we broke on length, keep everything
											(i32.const 0)
											;; eow found, one less, skip it
											(i32.const 1)
											;; no match and length exhausted?
											(local.get $is_len))))

								;; NOTE The string here is transient - callers should ensure that they
								;; have their own copy (and it should be copied for forth inside builtins)
								;; (ptr, len)
								(return
									(i32.add (local.get $str) (local.get $idx_find))
									(local.get $len)))

							;; nothing matches, we will continue
							(else)))

					;; still on leading whitespace, continue
					(else))

				;; continue
				br $loop))

		;; (ptr, len)
		i32.const 0
		i32.const 0
	)
