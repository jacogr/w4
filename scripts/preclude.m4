m4_define(`m4_require_w4',
`m4_ifdef(`__m4_req_$1__', `',
`m4_define(`__m4_req_$1__', 1)
( : $1 )
m4_include(`$1')
( ; $1 )
')')
