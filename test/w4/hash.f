\ -------------------------------------------------------------
testing Running djb2a tests
T{ s" " djb2a -> #5381 }T	\ default 0 length
T{ s" h" djb2a -> #177613 }T
T{ s" he" djb2a -> #5861128 }T
T{ s" hel" djb2a -> #193417316 }T
T{ s" hell" djb2a -> #2087804040 }T
T{ s" hello" djb2a -> #178056679 }T
T{ s" hello " djb2a -> #1580903143 }T
T{ s" hello w" djb2a -> #630196144 }T
T{ s" hello wo" djb2a -> #3616603615 }T
T{ s" hello wor" djb2a -> #3383802317 }T
T{ s" hello worl" djb2a -> #4291293953 }T
T{ s" hello world" djb2a -> #4173747013 }T

\ -------------------------------------------------------------
testing Running fnv1a tests
T{ s" " fnv1a -> #2166136261 }T	\ default 0 length
T{ s" h" fnv1a -> #3977000791 }T
T{ s" he" fnv1a -> #1547363254 }T
T{ s" hel" fnv1a -> #179613742 }T
T{ s" hell" fnv1a -> #477198310 }T
T{ s" hello" fnv1a -> #1335831723 }T
T{ s" hello " fnv1a -> #3801292497 }T
T{ s" hello w" fnv1a -> #1402552146 }T
T{ s" hello wo" fnv1a -> #3611200775 }T
T{ s" hello wor" fnv1a -> #1282977583 }T
T{ s" hello worl" fnv1a -> #2767971961 }T
T{ s" hello world" fnv1a -> #3582672807 }T

\ -------------------------------------------------------------
testing Running fnv1a + fmix32 via host::hash tests
T{ $12345 0 host::hash -> $0 }T	\ zero length
T{ s" " host::hash -> $0 }T		\ zero length
T{ s" h" host::hash -> $50FE4703 }T
T{ s" he" host::hash -> $108DDF7D }T
T{ s" hel" host::hash -> $737871E2 }T
T{ s" hell" host::hash -> $72AF205E }T
T{ s" hello" host::hash -> $-77728992 }T
T{ s" hello " host::hash -> $60FCEB66 }T
T{ s" hello w" host::hash -> $216C6C08 }T
T{ s" hello wo" host::hash -> $-25EDB6CC }T
T{ s" hello wor" host::hash -> $4DBE4336 }T
T{ s" hello worl" host::hash -> $13DB95C }T
T{ s" hello world" host::hash -> $-46FBA914 }T
