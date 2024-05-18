(require-macros :macros)
(require :vector)
                                        ; (fn collision-sphere-sphere [a b]
                                        ;   (todo))
(local physics {})

(fn collision-sphere-point [s p]
  (let [direction (vector.subtract p s.position)
        normal (vector.normalize direction)
        len (vector.length direction)
        penetration-depth (- s.radius len)]
    (if (> penetration-depth 0)
        {:mtv (-> normal (vector.scale penetration-depth))
         :contact (-> normal (vector.scale s.radius))}
        nil)))

(fn point-lies-between [p a b]
  (let [n (-> (vector.subtract a b))
        pd (vector.dot p n)
        ad (vector.dot a n)
        bd (vector.dot b n)]
    (>or< ad pd bd)))

(fn project-point-line-segment [p a b]
  (let [ap (vector.subtract p a)
        ab (vector.subtract b a)]
    (vector.add a (vector.scale ab (/ (vector.dot ap ab) (vector.dot ab ab))))))

(fn collision-sphere-line [s l]
  (let [closest-point (project-point-line-segment s.position (. l 1) (. l 2))]
    (if (point-lies-between closest-point (. l 1) (. l 2))
      (collision-sphere-point s closest-point)
      (do
        (var longest (- (/ 1 0)))
        (var worst-mtv nil)
        (each [k v (ipairs l)]
          (let [mtv (collision-sphere-point s v)
                len (vector.length-sq (or (and mtv mtv.mtv) vector.zero))]
            (when (and mtv (> len longest))
              (set longest len)
              (set worst-mtv mtv))))
        worst-mtv))))

(fn collision-point-tri-barycentric [p tri]
  (let [v0 (vector.subtract tri.b tri.a)
        v1 (vector.subtract tri.c tri.a)
        v2 (vector.subtract p tri.a)
        d00 (vector.dot v0 v0)
        d01 (vector.dot v0 v1)
        d11 (vector.dot v1 v1)
        d20 (vector.dot v2 v0)
        d21 (vector.dot v2 v1)
        denom (- (* d00 d11) (* d01 d01))
        v (/ (- (* d11 d20) (* d01 d21)) denom)
        w (/ (- (* d00 d21) (* d01 d20)) denom)
        u (- 1 v w)]
    (and (<= 0 v 1) (<= 0 w 1) (<= 0 u 1))))

(fn tri-normal [tri]
  (let [a (vector.subtract tri.b tri.a)
        b (vector.subtract tri.c tri.a)]
    (vector.normalize {:x (- (* a.y b.z) (* a.z b.y))
                       :y (- (* a.z b.x) (* a.x b.z))
                       :z (- (* a.x b.y) (* a.y b.x))})))

(fn distance-plane-point-normal [p n o]
  (-> p
    (vector.subtract o)
    (vector.dot n)))

(fn nearest-point-sphere-normal [s n]
  (-> n (vector.scale (- s.radius)) (vector.add s.position)))

;; TODO: collision should work on triangles that wind counter clockwise, not clockwise
(fn collision-sphere-tri [s t]
  (let [point-in-tri (collision-point-tri-barycentric s.position t)
        normal (tri-normal t)
        nearest (nearest-point-sphere-normal s normal)
        penetration-depth (- (distance-plane-point-normal nearest normal t.a))]
    (if (and point-in-tri (> penetration-depth 0))
        {:mtv (vector.scale normal penetration-depth)}
        (do
          (var longest (- (/ 1 0)))
          (var worst-mtv nil)
                                        ; TODO: i think triangles are better treated as arrays than tables
          (each [k v (lume2.pairs-2-looped-window [t.a t.b t.c])]
            (let [mtv (collision-sphere-line s v)
                  len (vector.length-sq (or (and mtv mtv.mtv) vector.zero))]
              (when (and mtv (> len longest))
                (set longest len)
                (set worst-mtv mtv))))
          (when worst-mtv
            (comment 
             (and worst-mtv worst-mtv.mtv {:mtv worst-mtv.mtv}))
            (love.graphics.print (inspect worst-mtv.mtv) 10 100
                                 )
            {:mtv (vector.invert worst-mtv.mtv)})))))

{:collision-sphere-tri collision-sphere-tri
:tri-normal tri-normal}
