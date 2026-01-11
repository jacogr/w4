
(;

	imports.wat

	wasi imports as exposed and used in the environment

;)

	;; Opens a file relative to a directory preopen.
	;; (dirfd:i32, dirflags:i32, path_ptr:i32, path_len:i32,
	;;  oflags:i32, fs_rights_base:i64, fs_rights_inheriting:i64,
	;;  fdflags:i32, opened_fd_ptr:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "path_open"
		(func $__wasi::path_open
			(param i32 i32 i32 i32 i32 i64 i64 i32 i32)
			(result i32)))

	;; Reads from an open file descriptor into memory described by iovecs.
	;; (fd:i32, iovs_ptr:i32, iovs_len:i32, nread_ptr:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "fd_read"
		(func $__wasi::fd_read
			(param i32 i32 i32 i32)
			(result i32)))

	;; Writes to an open file descriptor from memory described by iovecs.
	;; For Node convention: fd 1 = stdout, fd 2 = stderr.
	;; (fd:i32, iovs_ptr:i32, iovs_len:i32, nwritten_ptr:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "fd_write"
		(func $__wasi::fd_write
			(param i32 i32 i32 i32)
			(result i32)))

	;; Closes an already-open file descriptor.
	;; (fd:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "fd_close"
		(func $__wasi::fd_close
			(param i32)
			(result i32)))
