
\ -------------------------------------------------------------
testing LOOKUP

(new-lookup-small) constant widtest

\ make a visible xt with a permanently stored (lowercased) name
: mkxt ( c-addr u -- xt )
  strdup-ni                 ( c-addr' u' )
  0 (flg-is-vis) (new-xt)       ( c-addr' u' xt )
  dup >r                         ( c-addr' u' xt ) ( r: xt )
  (xt>str+len+hash!)             ( c-addr' u' xt -- )
  r>                             ( -- xt )
;

: addxt ( c-addr u -- )
  mkxt                           ( xt )
  widtest swap                   ( wid xt )
  (lookup-append) drop           ( -- )
;

\ populate two entries
s" mac1" addxt
s" mac2" addxt

T{ s" nope" widtest (lookup-search-xt) -> 0 }T

T{
  s" mac1" widtest (lookup-search-xt)
  (xt>str+len@) s" mac1" streq-ni
  -> TRUE
}T

T{
  s" mac2" widtest (lookup-search-xt)
  (xt>str+len@) s" mac2" streq-ni
  -> TRUE
}T

T{
  s" MaC1" widtest (lookup-search-xt)
  (xt>str+len@) s" mac1" streq-ni
  -> TRUE
}T
