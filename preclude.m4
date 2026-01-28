m4_define(`m4_require', `m4_ifdef(`__m4_req_$1__', `',
\ *** start-of $1
`m4_define(`__m4_req_$1__', 1)
m4_include(`$1')
\ *** end-of $1
')')
