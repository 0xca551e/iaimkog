(fn += [x by] `(set ,x (+ ,x ,by)))
(fn -= [x by] `(set ,x (- ,x ,by)))
(fn *= [x by] `(set ,x (* ,x ,by)))
(fn /= [x by] `(set ,x (/ ,x ,by)))
(fn >or< [...]
  `(or (> ,...) (< ,...)))

{:+= +=
 :-= -=
 :*= *=
 :/= /=
 :>or< >or<}
