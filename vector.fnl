(set _G.vector {})

(set _G.vector.zero {:x 0 :y 0 :z 0})

(fn _G.vector.string [v]
  (.. (tostring v.x) ", " (tostring v.y) ", " (tostring v.z)))

(fn _G.vector.add [a b]
  {:x (+ a.x b.x)
   :y (+ a.y b.y)
   :z (+ a.z b.z)})

(fn _G.vector.cross [a b]
  {:x (- (* a.y b.z) (* a.z b.y))
   :y (- (* a.z b.x) (* a.x b.z))
   :z (- (* a.x b.y) (* a.y b.x))})

(fn _G.vector.dot [a b]
  (+ (* a.x b.x) (* a.y b.y) (* a.z b.z)))

(fn _G.vector.invert [v]
  {:x (- v.x)
   :y (- v.y)
   :z (- v.z)})

(fn _G.vector.length [v]
  (-> v
    (_G.vector.length-sq)
    (math.sqrt)
    (or 0)))

(fn _G.vector.length-sq [v]
  (+ (* v.x v.x) (* v.y v.y) (* v.z v.z)))

(fn _G.vector.lerp [a b t]
  {:x (* (+ a.x t) (- b.x a.x))
   :y (* (+ a.y t) (- b.y a.y))
   :z (* (+ a.z t) (- b.z a.z))})

(fn _G.vector.multiply [a b]
  {:x (* a.x b.x)
   :y (* a.y b.y)
   :z (* a.z b.z)})

(fn _G.vector.normalize [v]
  (_G.vector.scale v (/ 1.0 (_G.vector.length v))))

(fn _G.vector.scale [v s]
  {:x (* v.x s)
   :y (* v.y s)
   :z (* v.z s)})

(fn _G.vector.subtract [a b]
  {:x (- a.x b.x)
   :y (- a.y b.y)
   :z (- a.z b.z)})

(fn _G.vector.reflect [v n]
  (let [d (_G.vector.dot v n)
        projected-vector (_G.vector.scale n d)
        +2pv (_G.vector.scale projected-vector 2)]
    (_G.vector.subtract v +2pv)))
(comment
 (_G.vector.reflect {:x -3 :y 3 :z -1} {:x 0 :y 0 :z 1}))
