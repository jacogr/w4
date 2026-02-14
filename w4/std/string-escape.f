m4_require_w4(`std/constants.f')
m4_require_w4(`std/file.f')
m4_require_w4(`std/logic.f')
m4_require_w4(`std/memory.f')
m4_require_w4(`std/parse.f')
m4_require_w4(`std/stack.f')
m4_require_w4(`std/string-format.f')

\ https://forth-standard.org/standard/core/Dotp
\
\ Parse and display ccc delimited by ) (right parenthesis). .( is an
\ immediate word.

	: (type-cr) type cr ;

	: .( ( "ccc<paren>" -- ) ')' ['] (type-cr) (parse-multi) ; immediate

\ https://forth-standard.org/standard/core/Seq
\
\ Parse ccc delimited by " (double-quote), using the translation rules below.
\ Append the run-time semantics given below to the current definition.
\
\ implementation from original proposal:
\ http://www.forth200x.org/escaped-strings.html

	create (s"\-result)
		string-max 1+ allot                   \ 256 + count byte

	create (s"\-escapetable)
		 #7 c,	\ \a bel
		 #8 c,	\ \b bs
		'c' c,	\ \c
		'd' c,	\ \d
		#27 c,	\ \e esc
		#12 c,	\ \f ff
		'g' c,	\ \g
		'h' c,	\ \h
		'i' c,	\ \i
		'j' c,	\ \j
		'k' c,	\ \k
		#10 c,	\ \l lf
		'm' c,	\ \m  (note: handled specially below)
		#10 c,	\ \n  (unix lf; \n handled specially below)
		'o' c,	\ \o
		'p' c,	\ \p
		'"' c,	\ \q  => "
		#13 c,	\ \r cr
		's' c,	\ \s
		 #9 c,	\ \t ht
		'u' c,	\ \u
		#11 c,	\ \v vt
		'w' c,	\ \w
		'x' c,	\ \x  (note: handled specially below)
		'y' c,	\ \y
		 #0 c,	\ \z nul

	create (s"\-crlf)
		#2 c,  #13 c,  #10 c,

	: (s"\-addchar) ( char $dest -- )
		tuck count + c!
		#1 swap c+!
	;

	: (s"\-append) ( c-addr u $dest -- )
		>r
		tuck r@ count + swap cmove
		r> c+!
	;

	: (s"\-extractnum)
		base @ >r  base !
		0 0 2swap >number 2swap drop
		r> base !
	;

	: (s"\-addescape) ( c-addr len dest -- c-addr' len' )
		over 0<> if
			>r		( r: -- dest )

			\ octal?
			over c@ '0' '8' within if \ '0' .. '7' + 1
				8 (s"\-extractnum)
				r> (s"\-addchar)
			else
				\ hex?
				over c@ 'x' = if
					1 /string
					>r 2 #16 (s"\-extractnum) nip
					r> 2 - swap
					r> (s"\-addchar)
				else
					\ crlf?
					over c@ 'm' = if
						1 /string #13 r@ (s"\-addchar) #10
						r> (s"\-addchar)
					else
						\ crlf?
						over c@ 'n' = if
							1 /string (s"\-crlf) count
							r> (s"\-append)
						else
							\ a..z?
							over c@ 'a' '{' within if \ 'a' .. 'z' + 1
								over c@ [char] a - (s"\-escapetable) +
							else
								over
							then

							c@
							r> (s"\-addchar)
							1 /string
						then
					then
				then
			then
		else drop then
	;

	: (s"\-parse) ( c-addr len dest -- c-addr' len' )
		dup >r 0 swap c!

		begin
			dup
		while
			over c@ '"' <>
		while
			over c@ '\' = if
				#1 /string r@ (s"\-addescape)
			else
				over c@ r@ (s"\-addchar) #1 /string
			then
		repeat then

		dup if #1 /string then
		r> drop
	;

	: (s"\-readescaped) ( "ccc" -- c-addr )
		source >in @ /string tuck
  		(s"\-result) dup >r (s"\-parse)
  		nip - >in +! r>
	;

	: S\"
		(s"\-readescaped) count
		state @ if
			string,
		then
	; immediate
