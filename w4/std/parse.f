
\ https://forth-standard.org/standard/file/INCLUDE

	: include ( i * x "name" -- j * x ) parse-name included	;

\ https://forth-standard.org/standard/core/Tick

	: ?parse-name ( "name" -- c-addr u ) parse-name dup 0= #-16 and throw ;

	: ?find-name ( c-addr u -- nt ) find-name dup 0= #-13 and throw ;

	: ' ( "name" -- xt ) ?parse-name ?find-name name>xt ;

\ https://forth-standard.org/standard/core/BracketTick

	: ['] ( -- xt ) ' lit, ; immediate
