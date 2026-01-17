require stack.f
require text.f

\ creates a stub for a function, when executed shows a message
\ that shows that this is a TODO item
\
\ NOTE We use the low-level build, here instead of create since we
\ want access to the actual string name as parsed

	: :unimplemented
		parse-name							( -- c-addr u )
		dup 0= #-16 and throw
		2dup								( c-addr u -- c-addr u c-addr u )
		build,								( c-addr u c-addr u -- c-addr u )
		s" [TODO: not implemented]: "		( c-addr u -- c-addr u c-addr u )
		string,	postpone type
		string, postpone type
		reveal
	;

\ unimplemented names

	:unimplemented restore-input
	:unimplemented save-input
