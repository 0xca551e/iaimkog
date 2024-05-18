(local vector {})

(set vector.zero {:x 0 :y 0 :z 0})

(fn vector.string [v]
  (.. (tostring v.x) ", " (tostring v.y) ", " (tostring v.z)))

(fn vector.add [a b]
  {:x (+ a.x b.x)
   :y (+ a.y b.y)
   :z (+ a.z b.z)})

(fn vector.cross [a b]
  {:x (- (* a.y b.z) (* a.z b.y))
   :y (- (* a.z b.x) (* a.x b.z))
   :z (- (* a.x b.y) (* a.y b.x))})

(fn vector.dot [a b]
  (+ (* a.x b.x) (* a.y b.y) (* a.z b.z)))

(fn vector.invert [v]
  {:x (- v.x)
   :y (- v.y)
   :z (- v.z)})

(fn vector.length [v]
  (-> v
    (vector.length-sq)
    (math.sqrt)
    (or 0)))

(fn vector.length-sq [v]
  (+ (* v.x v.x) (* v.y v.y) (* v.z v.z)))

(fn vector.lerp [a b t]
  {:x (* (+ a.x t) (- b.x a.x))
   :y (* (+ a.y t) (- b.y a.y))
   :z (* (+ a.z t) (- b.z a.z))})

(fn vector.multiply [a b]
  {:x (* a.x b.x)
   :y (* a.y b.y)
   :z (* a.z b.z)})

(fn vector.normalize [v]
  (vector.scale v (/ 1.0 (vector.length v))))

(fn vector.scale [v s]
  {:x (* v.x s)
   :y (* v.y s)
   :z (* v.z s)})

(fn vector.subtract [a b]
  {:x (- a.x b.x)
   :y (- a.y b.y)
   :z (- a.z b.z)})

(fn vector.reflect [v n]
  (let [d (vector.dot v n)
        projected-vector (vector.scale n d)
        +2pv (vector.scale projected-vector 2)]
    (vector.subtract v +2pv)))
(comment
 (vector.reflect {:x -3 :y 3 :z -1} {:x 0 :y 0 :z 1}))

vector
