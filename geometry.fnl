(set _G.geometry {})

(fn _G.geometry.translate-tri [tri d]
  {:a (_G.vector.add tri.a d)
   :b (_G.vector.add tri.b d)
   :c (_G.vector.add tri.c d)})
(comment
 (_G.translate-tri {:a {:x 0 :y 0 :z 0}
                    :b {:x 0 :y 1 :z 0}
                    :c {:x 1 :y 0 :z 0}}
                   {:x 2 :y 2 :z 2}))

(fn _G.geometry.translate-tris [tris d]
  (lume.map tris (fn [x] [(_G.geometry.translate-tri x d)
                          {:min {:x d.x :y d.y :z d.z}
                           :max {:x (+ d.x 1) :y (+ d.y 1) :z (+ d.z 1)}}])))

(fn _G.geometry.translate-edge [edge d]
  [(_G.vector.add (. edge 1) d) (_G.vector.add (. edge 2) d)])
(fn _G.geometry.translate-edges [edges d]
  (lume.map edges (fn [x] (_G.geometry.translate-edge x d))))

(fn _G.geometry.translate-verts [verts d]
  (lume.map verts (fn [x] (_G.vector.add x d))))

(fn _G.geometry.close-loop [lines]
  (let [first-segment (. lines 1)
        last-segment (. lines (# lines))
        first-vertex (. first-segment 1)
        last-vertex (. last-segment 2)]
    (lume.concat lines [[last-vertex first-vertex]])))
(comment
 (_G.geometry.close-loop (window-by-2 [{:x 0 :y 0 :z 0} {:x 1 :y 1 :z 0} {:x 0 :y 1 :z 0}])))


(fn _G.geometry.fan-tris [base segments]
  (lume.map segments (fn [x]
                       ;; (print (inspect (. segments 1)))
                       {:a base :b (. x 2) :c (. x 1)})))

(fn _G.geometry.extrude-line-to-rect [line offset flip]
  (let [a (. line (if flip 1 2))
        ;; t (print "this")
        ;; t (print a)
        b (. line (if flip 2 1))
        c (_G.vector.add a offset)
        d (_G.vector.add b offset)]
    (_G.geometry.rect-tris a b c d)))

(fn _G.geometry.prepend-point [segment p]
  (lume.concat [[p (lume.first (lume.first segment))]] segment))

(fn _G.geometry.append-point [segment p]
  (lume.concat segment [[(lume.last (lume.last segment)) p]]))


(fn _G.geometry.to-isometric [x y z]
  (let [ix (/ (* (- x y) _G.tile-width) 2)
        iy (/ (* (- (+ x y) z) _G.tile-height) 2)]
    [ix iy]))
                                        ; a---b
                                        ; |   |
                                        ; c---d
;; TODO: make tris work counter-clockwise
(fn _G.geometry.rect-tris [a b c d]
  ;; [{:a a :b c :c b}
  ;;  {:a b :b c :c d}]
  [{:a a :b b :c c}
   {:a b :b d :c c}]
  )


;; note: assumes circle faces upwards
(fn _G.geometry.make-circle-verts [center radius resolution]
  (let [radians (-> (_G.util.range 0 (- resolution 1) 1)
                    (lume.map (fn [x]
                                (-> x
                                    (* math.pi 2)
                                    (/ resolution)))))
        positions (-> radians
                      (lume.map (fn [x]
                                  (-> {:x (math.cos x) :y (math.sin x) :z 0}
                                      (_G.vector.scale radius)
                                      (_G.vector.add center)))))]
    positions))

(fn _G.geometry.tri-edges [tris]
  (local result [])
  (each [_ tri (ipairs tris)]
    (_G.util.concat-mut result [[tri.a tri.b]
                      [tri.b tri.c]
                      [tri.c tri.a]]))
  result)

(fn _G.geometry.tri-verts [tris]
  (local result [])
  (each [_ tri (ipairs tris)]
    (_G.util.concat-mut result [tri.a tri.b tri.c]))
  result)
