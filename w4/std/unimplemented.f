require stack.f
require text.f

\ creates a stub for a function, when executed shows a message
\ that shows that this is a TODO item

	: :umimplemented
		parse-name							( -- c-addr u )
		dup 0= #-16 and throw
		2dup								( c-addr u -- c-addr u c-addr u )
		build,								( c-addr u c-addr u -- c-addr u )
		s" [TODO] (unimplemented): "		( c-addr u -- c-addr u c-addr u )
		string,								( c-addr u c-addr u -- c-addr u )
		['] type compile,
		string,								( c-addr u -- )
		['] type compile,
		reveal
	;

\ unimplemented names

	:umimplemented restore-input
	:umimplemented save-input
