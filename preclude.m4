m4_define(`m4_include_w4', `m4_esyscmd(`sed -e "/^[[:space:]]*$/d" -e "/^[[:space:]]*\\\\/d" "w4/$1"')')

m4_define(`m4_require_w4', `m4_ifdef(`__m4_req_$1__', `',
\ *** start-of $1
`m4_define(`__m4_req_$1__', 1) m4_include_w4(`$1')
\ *** end-of $1
')')
