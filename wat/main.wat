;; Copyright (c) 2025 Authors and contributors.
;; Distributed under the MIT license. See LICENSE for details.

;; Small forth interpreter in WASM

(module

	m4_include(`imports.wat')
	m4_include(`memory.wat')

	m4_include(`forth/builtins.wat')
	m4_include(`forth/exceptions.wat')
	m4_include(`forth/internal.wat')
	m4_include(`forth/load.wat')
	m4_include(`forth/math.wat')

	m4_include(`assert.wat')
	m4_include(`file.wat')
	m4_include(`hash.wat')
	m4_include(`iov.wat')
	m4_include(`list.wat')
	m4_include(`list-entry.wat')
	m4_include(`lookup.wat')
	m4_include(`number.wat')
	m4_include(`source.wat')
	m4_include(`stack.wat')
	m4_include(`string.wat')
	m4_include(`util.wat')

	m4_ifdef(`DEBUG', `m4_include(`debug.wat')')

(;

	main.wat

	Global wasi entry point and logic. This export is defined
	as part of the wasi standard, allowing the user to call
	"start" and beging execution.

;)

	;;
	;; Initializes the process with all initial allocations. Additionally
	;; execute all base/embedded forth sources before the user code is
	;; executed.
	;;
	(func (export "_start")
		(local $str i32)
		(local $len i32)

		;; set the current alloc position (after execption, end of constant memory)
		(i32.store (global.get $PTR_ALLOC) (call $__excep_init))

		;; allocate dictionary
		(i32.store (global.get $PTR_PTR_WID_LIST) (call $__alloc (i32.mul (i32.const 16) (i32.const 4))))
		(i32.store (global.get $PTR_WID_CURR) (call $__store (global.get $PTR_WID_ORIG) (call $__dict_init (i32.const 1024))))
		(i32.store (i32.load (global.get $PTR_PTR_WID_LIST)) (i32.load (global.get $PTR_WID_CURR)))

		;; allocate stacks, all with global pointers
		(global.set $stack_dat (call $__store (global.get $PTR_PTR_STACK_DAT) (call $__stack_new)))
		(global.set $stack_ret (call $__store (global.get $PTR_PTR_STACK_RET) (call $__stack_new)))
		(global.set $stack_src (call $__store (global.get $PTR_PTR_STACK_SRC) (call $__stack_new)))

		;; set the alloc start/end for checks
		(i32.store (global.get $PTR_ALLOC_MIN) (i32.load (global.get $PTR_ALLOC)))
		(i32.store (global.get $PTR_ALLOC_MAX) (global.get $w4_forth_start))

		;; save the exit pointer for token lists
		(global.set $dict_exit_ptr (call $__val_get_value (call $__list_get_head (i32.load (global.get $PTR_WID_CURR)))))

		;; execute embedded
		(call $__internal_evaluate (global.get $w4_forth_start) (global.get $w4_forth_size))

	m4_ifdef(`DEBUG', `
		;; DERUG, emit dictionary
		(call $__DEBUG_emit_dict)
	')
	)

	m4_include(`build/w4-forth.wat')
)
