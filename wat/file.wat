
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
	(func $__file_open (param $path i32) (param $path_len i32) (result i32 i32)
		(local $err i32)
		(local $fd i32)
		(local $pd i32)
		(local $rb i64)

		;; start with $pd=3 (user location)
		(local.set $pd (i32.const 3))

		(block $exit (loop $loop
			;; $pd <= 4 else -38 non-existent file
			(call $__assert (i32.le_u (local.get $pd) (i32.const 4)) (i32.const -38))

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
						;; 44, not found?
						(i32.eq (local.get $err) (i32.const 44)) (if

							;; not found, try next directory
							(then (local.set $pd (i32.add (local.get $pd) (i32.const 1))))

							;; other errors, -37 file I/O exception
							(else (call $__assert (i32.const 0) (i32.const -37)))))

					;; no error, get fd, break to return
					(else
						(local.set $fd (i32.load (global.get $PTR_PRI_IN)))
						(br $exit)))

			;; loop next
			(br $loop)))

		;; ensure that we have a valid fd
		(call $__assert (local.get $fd) (i32.const -38))

		;; return (pd, fd)
		local.get $pd
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
