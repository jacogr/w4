m4_require_w4(`std/stack.f')
m4_require_w4(`std/string-format.f')

\ creates a stub for a function, when executed shows a message
\ that shows that this is a TODO item
\
\ NOTE We use the low-level build, here instead of create since we
\ want access to the actual string name as parsed

	: :UNIMPLEMENTED
		parse-name							( -- c-addr u )

		\ -16 attempt to use zero-length string as a name
		dup 0= #-16 and throw

		2dup								( c-addr u -- c-addr u c-addr u )
		build,								( c-addr u c-addr u -- c-addr u )
		s" [TODO: not implemented]: "		( c-addr u -- c-addr u c-addr u )
		string,	postpone type
		string, postpone type
		0 lit, 0 lit, 0 lit,
		reveal
	;

\ unimplemented names
