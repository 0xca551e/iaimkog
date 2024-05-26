(fn += [x by] `(set ,x (+ ,x ,by)))
(fn -= [x by] `(set ,x (- ,x ,by)))
(fn *= [x by] `(set ,x (* ,x ,by)))
(fn /= [x by] `(set ,x (/ ,x ,by)))
(fn %= [x by] `(set ,x (% ,x ,by)))
(fn >or< [...]
  `(or (> ,...) (< ,...)))
(fn todo! []
  (print "todo statement reached"))

{:+= +=
 :-= -=
 :*= *=
 :/= /=
 :%= %=
 :>or< >or<
 :todo! todo!}
