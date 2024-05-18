(local lume-ext {})

(fn lume-ext.concat-mut [t1 t2]
  (for [i 1 (# t2)]
    (tset t1 (+ (# t1) 1) (. t2 i)))
  t1)

(fn lume-ext.pairs-2-looped-window [t]
  (var i 0)
  (local n (# t))
  (fn []
    (set i (+ i 1))
    (if
     (= i n) (values i [(. t i) (. t 1)])
     (< i n) (values i [(. t i) (. t (+ 1 i))]))))
(comment
 (each [a b (lume-ext.pairs-2-looped-window [ 1 2 3 ])] (print a (. b 1) (. b 2))))

lume-ext
