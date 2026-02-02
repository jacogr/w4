
(;

	file.wat

	File handling routines that are more than "just a call to wasmi::*".
	It handles opening of files (either from user directories or library
	directories) as well as reading lines from files.

;)

	;; 1<<1  FD_READ         = 0x00000002
	;; 1<<21 FD_FILESTAT_GET = 0x00200000
	(global $FILE_FLAGS_RO i64 (i64.const 0x00200002))

	;;
	;; Opens a file for either the fd=3 or fd=4 directories,
	;; returning the path_fd and file_fd, or exception if we
	;; cannot open the file
	;;
	(func $__file_open (param $path i32) (param $path_len i32) (result i32)
		(local $err i32)
		(local $fd i32)
		(local $pd i32)
		(local $rb i64)

		;; start with $pd=3 (user location)
		(local.set $pd (i32.const 3))

		;; attempt to open the file, check errorno != 0 for error
		(local.tee $err
			(call $__wasi::path_open
				(local.get $pd)               ;; dirfd (preopened)
				(i32.const 0)                 ;; dirflags
				(local.get $path)             ;; path_ptr
				(local.get $path_len)         ;; path_len
				(i32.const 0)                 ;; oflags (0 = no create/trunc
				(global.get $FILE_FLAGS_RO)
				(i64.const 0)                 ;; rights_inheriting
				(i32.const 0)                 ;; fdflags
				(global.get $PTR_PRI_IN))) (if

				;; non-zero errno, examine further
				(then
					 (call $__assert
					 	(i32.const 0)
						(select
							;; not found
							(i32.const -38)
							;; other error
							(i32.const -37)
							;; not found?
							(i32.eq (local.get $err) (i32.const 44)))))

				;; no error, get fd
				(else (local.set $fd (i32.load (global.get $PTR_PRI_IN)))))

		;; return fd
		local.get $fd
	)

	;;
	;; Refill the current line buffer from an open file frame.
	;;
	;; in:   fstruct (i32)
	;; out:  i32  (1 = produced a line, 0 = EOF and no line)
	;;
	;; Uses:
	;;   - iov_in + off_in as the read stash (valid bytes + cursor)
	;;   - iov_ln as output line buffer (len set to produced line length)
	;;   - IDX_SRC_IS_EOF set on EOF
	;;
	(func $__file_read_line (param $s i32) (result i32)
		(local $fd i32)
		(local $iov_in i32)
		(local $in_ptr i32)
		(local $in_len i32)
		(local $off_in i32)
		(local $iov_ln i32)
		(local $ln_ptr i32)
		(local $ln_len i32)
		(local $ch i32)
		(local $nread i32)
		(local $had_nl i32)

		;; load frame pointers
		(local.set $fd     (call $__src_get_fd (local.get $s)))
		(local.set $iov_ln (call $__src_get_ln_iov (local.get $s)))
		(local.set $iov_in (call $__src_get_in_iov (local.get $s)))
		(local.set $off_in (call $__src_get_in_off (local.get $s)))

		;; extract useful values
		(local.set $ln_ptr (call $__iov_get_str (local.get $iov_ln)))
		(local.set $in_ptr (call $__iov_get_str (local.get $iov_in)))
		(local.set $in_len (call $__iov_get_len (local.get $iov_in)))

		;; reset line (len/off)
		(call $__iov_set_len    (local.get $iov_ln) (i32.const 0))
		(call $__src_set_ln_off (local.get $s)      (i32.const 0))

		(block $done (loop $loop
			;; offset >= length?
			(i32.ge_u (local.get $off_in) (local.get $in_len)) (if

				;; input exhausted
				(then
					;; exit on eof
					(br_if $done
						(call $__src_get_is_eof (local.get $s)))

					;; set pointers/length into read-into iov
					(call $__iov_set_str (global.get $PTR_PRI_IOV) (local.get $in_ptr))
					(call $__iov_set_len (global.get $PTR_PRI_IOV) (global.get $SIZEOF_SRC_IN))

					;; read from file, ensure no error, -37 file I/O exception
					(call $__assert
						(i32.eqz
							(call $__wasi::fd_read
								(local.get $fd)
								(global.get $PTR_PRI_IOV)
								(i32.const 1)
								(global.get $PTR_PRI_IN)))
						(i32.const -37))

					;; persist new in-buffer length and reset offset
					(local.set $off_in (i32.const 0))
					(call $__iov_set_len
						(local.get $iov_in)
						(local.tee $in_len
							(local.tee $nread
								(i32.load (global.get $PTR_PRI_IN))))))

				;; input still has data
				(else))

			;; if still empty (possible only via EOF), stop
			(br_if $done
				(i32.ge_u (local.get $off_in) (local.get $in_len)))

			;; ch = in_ptr[off_in++]
			(local.set $ch (i32.load8_u (i32.add (local.get $in_ptr) (local.get $off_in))))
			(local.set $off_in (i32.add (local.get $off_in) (i32.const 1)))

			;; newline ends line (and marks "line exists" even if empty)
			(br_if $done
				(local.tee $had_nl (i32.eq (local.get $ch) (i32.const 10))))

			;;ln_len < SIZEOF_SRC_LN, -18 parsed string overflow
			(call $__assert
				(i32.lt_u (local.get $ln_len) (global.get $SIZEOF_SRC_LN))
				(i32.const -18))

			;; append ch, then increment length
			(i32.store8
				(i32.add (local.get $ln_ptr) (local.get $ln_len))
				(local.get $ch))
			(local.set $ln_len (i32.add (local.get $ln_len) (i32.const 1)))

			(br $loop)))

		;; persist updated in offset
		(call $__src_set_in_off (local.get $s) (local.get $off_in))

		;; tailing \r?
		(i32.and
			(i32.gt_u (local.get $ln_len) (i32.const 0))
			(i32.eq
				(i32.load8_u
					(i32.add
						(local.get $ln_ptr)
						(i32.sub (local.get $ln_len) (i32.const 1))))
				(i32.const 13))) (if

			;; trailing \r found, remove it
			(then (local.set $ln_len (i32.sub (local.get $ln_len) (i32.const 1))))

			;; nothing found
			(else))

		;; publish line length
		(call $__iov_set_len (local.get $iov_ln) (local.get $ln_len))

		;; return:
		;;  - 1 if we have any chars OR we hit '\n' (empty line is valid)
		;;  - 0 only when EOF and no chars and no '\n'
		(i32.or
			(i32.ne (local.get $ln_len) (i32.const 0))
			(local.get $had_nl))
	)

	;;
	;; Reads a line from a meory location, mirroring the details
	;; for __file_read_line
	;;
	(func $__mem_read_line (param $s i32) (result i32)
		(local $ptr i32)
		(local $buf_len i32)
		(local $off i32)
		(local $start i32)
		(local $i i32)
		(local $ln_len i32)
		(local $had_nl i32)
		(local $iov_ln i32)

		;; output line iov
		(local.set $iov_ln (call $__src_get_ln_iov (local.get $s)))

		;; reset line (len/off) like file does
		(call $__iov_set_len    (local.get $iov_ln) (i32.const 0))
		(call $__src_set_ln_off (local.get $s)      (i32.const 0))

		;; already EOF? (match file behavior: once EOF, keep returning 0)
		(call $__src_get_is_eof (local.get $s)) (if

			;; eof, early exit
			(then (return (i32.const 0)))

			;; not eof, continue
			(else))

		;; load source buffer + cursor
		(local.set $ptr     (call $__src_get_ptr (local.get $s)))
		(local.set $buf_len (call $__src_get_len (local.get $s)))
		(local.set $off     (call $__src_get_in_off (local.get $s)))

		;; EOF before starting?
		(i32.or
			(i32.eqz (local.get $ptr))
			(i32.ge_u (local.get $off) (local.get $buf_len))) (if

			;; set eof, continue
			(then (call $__src_set_is_eof (local.get $s) (i32.const 1))

			;; nothing read, return
			(return (i32.const 0))))

		;; scan from off until '\n' or EOF
		(local.set $start  (local.get $off))
		(local.set $i      (local.get $off))
		(local.set $had_nl (i32.const 0))

		(block $done (loop $loop
			;; end of buffer
			(br_if $done
				(i32.ge_u (local.get $i) (local.get $buf_len)))

			;; newline ends line (and marks "line exists" even if empty)
			(br_if $done
				(local.tee $had_nl
					(i32.eq
						(i32.load8_u (i32.add (local.get $ptr) (local.get $i)))
						(i32.const 10))))

			;; next char
			(local.set $i (i32.add (local.get $i) (i32.const 1)))
			(br $loop)))

		;; length excluding '\n'
		(local.set $ln_len
			(i32.sub (local.get $i) (local.get $start)))

		;; consume newline if present (advance absolute cursor)
		(local.get $had_nl) (if

			;; nl, consume
			(then (local.set $i (i32.add (local.get $i) (i32.const 1))))

			;; not nl, continue
			(else))

		;; persist cursor back to source (in_off)
		(call $__src_set_in_off (local.get $s) (local.get $i))

		;; if we are now at EOF after consuming, set eof flag (optional but aligns statefulness)
		(i32.ge_u (local.get $i) (local.get $buf_len)) (if

			;; eof, set flag
			(then (call $__src_set_is_eof (local.get $s) (i32.const 1)))

			;; not eof, continue
			(else))

		;; strip trailing '\r' (no copy, just shorten)
		(i32.and
			(i32.gt_u (local.get $ln_len) (i32.const 0))
			(i32.eq
				(i32.const 13)
				(i32.load8_u
					(i32.add
						(local.get $ptr)
						(i32.add
							(local.get $start)
							(i32.sub (local.get $ln_len) (i32.const 1))))))) (if

			;; \r
			(then
				(local.set $ln_len
					(i32.sub (local.get $ln_len) (i32.const 1))))

			;; not \r, ignore
			(else))

		;; publish line slice (pointer update only)
		(drop
			(call $__iov_fill
				(local.get $iov_ln)
				(i32.add (local.get $ptr) (local.get $start))
				(local.get $ln_len)
				(i32.const 0)))

		;; return:
		;;  - 1 if we have any chars OR we hit '\n' (empty line is valid)
		;;  - 0 only when EOF and no chars and no '\n'
		(i32.or
			(i32.ne (local.get $ln_len) (i32.const 0))
			(local.get $had_nl))
	)


	;;
	;; Join a relative include path against a base file path.
	;; Handles leading "../" segments in inc only.
	;;
	;; Returns (ptr, len)
	;;
	(func $__file_relative (param $base_ptr i32) (param $base_len i32) (param $inc_ptr i32) (param $inc_len i32) (result i32 i32)
		(local $slash i32)
		(local $dir_len i32)
		(local $ret_ptr i32)
		(local $ret_len i32)
		(local $dst i32)
		(local $prev i32)

		;; find last '/' in base path
		(local.set $dir_len
			(call $__strposr
				(i32.const 47) ;; '/'
				(local.get $base_ptr)
				(local.get $base_len)))

		;; absolute or empty dir?
		(i32.or
			(i32.eq
				(i32.load8_u (local.get $inc_ptr))
				(i32.const 47))
			(i32.eq (local.get $dir_len) (i32.const -1))) (if

			;; absolute or no slash, return as-is
			(then (return (local.get $inc_ptr) (local.get $inc_len)))

			;; valid, continue
			(else))

		;; consume leading "../" in include path
		(block $done_dotdot (loop $loop_dotdot
			;; need at least 3 bytes: '.' '.' '/'
			(br_if $done_dotdot
				(i32.lt_u (local.get $inc_len) (i32.const 3)))

			;; check "../"
			(br_if $done_dotdot
				(i32.eqz
					(i32.and
						(i32.and
							(i32.eq (i32.load8_u (local.get $inc_ptr)) (i32.const 46)) ;; '.'
							(i32.eq (i32.load8_u (i32.add (local.get $inc_ptr) (i32.const 1))) (i32.const 46))) ;; '.'
						(i32.eq (i32.load8_u (i32.add (local.get $inc_ptr) (i32.const 2))) (i32.const 47))))) ;; '/'

			;; pop one directory component from dir (if any)
			;; If dir_len == 0 => can't pop further; just drop the "../" anyway (clamp to empty)
			(local.get $dir_len) (if

				;; have a length
				(then
					;; find previous '/' within base[0..dir_len)
					(local.set $prev
						(call $__strposr
							(i32.const 47) ;; '/'
							(local.get $base_ptr)
							(local.get $dir_len)))

					;; dir_len = (prev >= 0) ? prev : 0
					(local.set $dir_len
						(select
							(local.get $prev)
							(i32.const 0)
							(i32.ge_s (local.get $prev) (i32.const 0)))))

				;; nothing remaining
				(else))

			;; advance inc past "../"
			(local.set $inc_ptr (i32.add (local.get $inc_ptr) (i32.const 3)))
			(local.set $inc_len (i32.sub (local.get $inc_len) (i32.const 3)))

			br $loop_dotdot))

		;; allocate: dir + / + include
		(local.set $ret_ptr
			(call $__alloc
				(local.tee $ret_len
					(i32.add
						(i32.add (local.get $dir_len) (i32.const 1))
						(local.get $inc_len)))))

		;; copy directory part
		(memory.copy
			(local.get $ret_ptr)
			(local.get $base_ptr)
			(local.get $dir_len))

		;; write '/'
		(i32.store8
			(local.tee $dst
				(i32.add (local.get $ret_ptr) (local.get $dir_len)))
			(i32.const 47))

		;; copy include filename (possibly trimmed)
		(memory.copy
			(i32.add (local.get $dst) (i32.const 1))
			(local.get $inc_ptr)
			(local.get $inc_len))

		;; return (ptr, len)
		local.get $ret_ptr
		local.get $ret_len
	)
