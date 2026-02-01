
\ -------------------------------------------------------------
testing OPEN-FILE, READ-LINE, CLOSE-FILE

variable this-id

T{ s" w4/file.f" r/o open-file swap dup this-id ! 0<> -> 0 true }T

$ff buffer: line-buf

: print-this
	0 0 0 0 false
	{: line-len flag ior lines done? :}

	begin
		done? 0=
	while
		line-buf $ff this-id @ read-line

		to ior
		to flag
		to line-len

		ior if
			true to done?
		else
			flag if
				true to done?
			else
				line-buf line-len type
				lines 1+ to lines
			then
		then
	repeat

	lines
;

\ here we test the number of lines in the file
T{ print-this -> 42 }T

T{ this-id @ close-file 0= -> true }T
