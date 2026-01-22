
\ -------------------------------------------------------------
testing lookup

(new-lookup-small) constant widtest

\ make a visible xt with a permanently stored (lowercased) name
: mkxt ( c-addr u -- xt )
  strdup-n-lower                 ( c-addr' u' )
  0 (flg-set-vis) (new-xt)       ( c-addr' u' xt )
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
  (xt>str+len@) s" mac1" streq-n
  -> TRUE
}T

T{
  s" mac2" widtest (lookup-search-xt)
  (xt>str+len@) s" mac2" streq-n
  -> TRUE
}T

T{
  s" MaC1" widtest (lookup-search-xt)
  (xt>str+len@) s" mac1" streq-n
  -> TRUE
}T

\ -------------------------------------------------------------
testing replaces & substitutes internals

\ assume (substName) exists
T{
  s" %mac1%" (formNameSubst) 2drop
  (substName) count s" mac1" streq-n
  -> TRUE
}T

T{ s" %mac1%" (formNameSubst) nip -> 0 }T

T{
  s" %mac1%" (formNameSubst) 2drop
  (substName) count nip
  -> 4
}T

\ create substitution "mac1" -> "wxyz"
T{ s" wxyz" s" mac1" replaces -> }T

\ now it must be findable
T{ s" mac1" (findSubst) 0<> -> TRUE }T

T{ s" wxyz" s" mac1" replaces -> }T

T{
  s" %mac1%" (formNameSubst) 2drop
  (substName) count (findSubst) 0<>
  -> TRUE
}T


