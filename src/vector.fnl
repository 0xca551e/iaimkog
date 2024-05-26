(set _G.vector {})

(set _G.vector.--zero {:x 0 :y 0 :z 0})
(set _G.vector.zero {})
(setmetatable _G.vector.zero
              {:__index _G.vector.--zero
               :__newindex (fn [table key value]
                             (error "Attempt to modify frozen table"))})

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

(fn _G.vector.rotate-by-axis-angle [vector axis angle]
  (let [cos-angle (math.cos angle)
        sin-angle (math.sin angle)
        one-minus-cos-angle (- 1 cos-angle)
        x vector.x
        y vector.y
        z vector.z
        u axis.x
        v axis.y
        w axis.z
        new-x (+ (+ (* (+ cos-angle
                          (* (* u u) one-minus-cos-angle))
                       x)
                    (* (+ (* (* u v) one-minus-cos-angle)
                          (* w sin-angle))
                       y))
                 (* (- (* (* u w) one-minus-cos-angle)
                       (* v sin-angle))
                    z))
        new-y (+ (+ (* (- (* (* u v) one-minus-cos-angle)
                          (* w sin-angle))
                       x)
                    (* (+ cos-angle
                          (* (* v v) one-minus-cos-angle))
                       y))
                 (* (+ (* (* v w) one-minus-cos-angle)
                       (* u sin-angle))
                    z))
        new-z (+ (+ (* (+ (* (* u w) one-minus-cos-angle)
                          (* v sin-angle))
                       x)
                    (* (- (* (* v w) one-minus-cos-angle)
                          (* u sin-angle))
                       y))
                 (* (+ cos-angle (* (* w w) one-minus-cos-angle))
                    z))]
    {:x new-x :y new-y :z new-z}))
(comment
 (let [vector {:x 1 :y 0 :z 0}
       axis {:x 0 :y 0 :z 1}
       angle (math.rad 90)
       rotated-vector (_G.vector.rotate-by-axis-angle vector axis angle)]
   (print (inspect rotated-vector))))

(fn _G.vector.move-towards [start target distance]
  (let [direction (_G.vector.subtract target start)
        magnitude (_G.vector.length direction)]
    (if (<= magnitude distance) target
        (let [normalized-direction (_G.vector.normalize direction)
              new-position (_G.vector.add start (_G.vector.scale normalized-direction distance))]
          new-position))))
(comment
  (_G.vector.move-towards {:x 0 :y 0 :z 0} {:x 3 :y 4 :z 5} 5)
  (_G.vector.move-towards {:x 0 :y 0 :z 0} {:x 3 :y 4 :z 5} 10)
  (_G.vector.move-towards {:x 0 :y 0 :z 0} {:x 3 :y 4 :z 5} 7.0710678118655))
