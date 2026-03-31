
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

	;; Move file offset.
	;; (fd:i32, offset:i64, whence:u8, newoffset_ptr:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "fd_seek"
		(func $__wasi::fd_seek
			(param i32 i64 i32 i32)
			(result i32)))

	;; Query current file offset.
	;; (fd:i32, offset_ptr:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "fd_tell"
		(func $__wasi::fd_tell
			(param i32 i32)
			(result i32)))

	;; Get filestat by open fd.
	;; (fd:i32, filestat_ptr:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "fd_filestat_get"
		(func $__wasi::fd_filestat_get
			(param i32 i32)
			(result i32)))

	;; Resize/truncate file by open fd.
	;; (fd:i32, size:i64) -> errno:i32
	(import "wasi_snapshot_preview1" "fd_filestat_set_size"
		(func $__wasi::fd_filestat_set_size
			(param i32 i64)
			(result i32)))

	;; Flush file data+metadata.
	;; (fd:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "fd_sync"
		(func $__wasi::fd_sync
			(param i32)
			(result i32)))

	;; Remove a directory entry for a file.
	;; (dirfd:i32, path_ptr:i32, path_len:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "path_unlink_file"
		(func $__wasi::path_unlink_file
			(param i32 i32 i32)
			(result i32)))

	;; Rename/move a path between directories.
	;; (old_dirfd:i32, old_ptr:i32, old_len:i32, new_dirfd:i32, new_ptr:i32, new_len:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "path_rename"
		(func $__wasi::path_rename
			(param i32 i32 i32 i32 i32 i32)
			(result i32)))

	;; Get filestat by path.
	;; (dirfd:i32, flags:i32, path_ptr:i32, path_len:i32, filestat_ptr:i32) -> errno:i32
	(import "wasi_snapshot_preview1" "path_filestat_get"
		(func $__wasi::path_filestat_get
			(param i32 i32 i32 i32 i32)
			(result i32)))
