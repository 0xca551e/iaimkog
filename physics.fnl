(require-macros :macros)

(set _G.physics {})

(fn _G.physics.collision-sphere-point [s p]
  (let [direction (_G.vector.subtract p s.position)
        normal (_G.vector.normalize direction)
        len (_G.vector.length direction)
        penetration-depth (- s.radius len)]
    (if (> penetration-depth 0)
        {:mtv (-> normal (_G.vector.scale (- penetration-depth)))
         :contact (-> normal (_G.vector.scale (- s.radius)))}
        nil)))

(fn _G.physics.point-lies-between [p a b]
  (let [n (-> (_G.vector.subtract a b))
        pd (_G.vector.dot p n)
        ad (_G.vector.dot a n)
        bd (_G.vector.dot b n)]
    (>or< ad pd bd)))

(fn _G.physics.project-point-line-segment [p a b]
  (let [ap (_G.vector.subtract p a)
        ab (_G.vector.subtract b a)]
    (_G.vector.add a (_G.vector.scale ab (/ (_G.vector.dot ap ab) (_G.vector.dot ab ab))))))

(fn _G.physics.collision-sphere-line [s l]
  (let [closest-point (_G.physics.project-point-line-segment s.position (. l 1) (. l 2))]
    (if (_G.physics.point-lies-between closest-point (. l 1) (. l 2))
        (_G.physics.collision-sphere-point s closest-point))))
(comment
 (_G.physics.collision-sphere-line {:position {:x 1 :y 0 :z 1} :radius 2}
                        {{:x 0 :y -1 :z 0} {:x 0 :y 1 :z 0}})
 (_G.physics.collision-sphere-line {:position {:x 1 :y -0.5 :z 1} :radius 2}
                                       [{:x 0 :y -1 :z 0} {:x 0 :y 1 :z 0}])
 (_G.physics.collision-sphere-line {:position {:x 1 :y 0.5 :z 1} :radius 2}))

(fn _G.physics.collision-point-tri-barycentric [p tri]
  (let [v0 (_G.vector.subtract tri.b tri.a)
        v1 (_G.vector.subtract tri.c tri.a)
        v2 (_G.vector.subtract p tri.a)
        d00 (_G.vector.dot v0 v0)
        d01 (_G.vector.dot v0 v1)
        d11 (_G.vector.dot v1 v1)
        d20 (_G.vector.dot v2 v0)
        d21 (_G.vector.dot v2 v1)
        denom (- (* d00 d11) (* d01 d01))
        v (/ (- (* d11 d20) (* d01 d21)) denom)
        w (/ (- (* d00 d21) (* d01 d20)) denom)
        u (- 1 v w)]
    (and (<= 0 v 1) (<= 0 w 1) (<= 0 u 1))))

(fn _G.physics.tri-normal [tri]
  (let [a (_G.vector.subtract tri.b tri.a)
        b (_G.vector.subtract tri.c tri.a)]
    (_G.vector.normalize {:x (- (* a.y b.z) (* a.z b.y))
                       :y (- (* a.z b.x) (* a.x b.z))
                       :z (- (* a.x b.y) (* a.y b.x))})))

(fn _G.physics.distance-plane-point-normal [p n o]
  (-> p
    (_G.vector.subtract o)
    (_G.vector.dot n)))

(fn _G.physics.nearest-point-sphere-normal [s n]
  (-> n (_G.vector.scale (- s.radius)) (_G.vector.add s.position)))

;; Todo: collision should work on triangles that wind counter clockwise, not clockwise
(fn _G.physics.collision-sphere-tri [s t]
  (let [point-in-tri (_G.physics.collision-point-tri-barycentric s.position t)
        normal (_G.physics.tri-normal t)
        nearest (_G.physics.nearest-point-sphere-normal s normal)
        penetration-depth (- (_G.physics.distance-plane-point-normal nearest normal t.a))]
    (if (and point-in-tri (> penetration-depth 0))
        {:mtv (_G.vector.scale normal penetration-depth)})))

(fn _G.physics.sphere-aabb [sphere]
  (let [{:position {:x center-x :y center-y :z center-z} :radius radius} sphere
        min-x (- center-x radius)
        min-y (- center-y radius)
        min-z (- center-z radius)
        max-x (+ center-x radius)
        max-y (+ center-y radius)
        max-z (+ center-z radius)]
    {:min {:x min-x :y min-y :z min-z}
     :max {:x max-x :y max-y :z max-z}}))
(comment
 (_G.physics.sphere-aabb _G.ball))

(fn _G.physics.aabb-overlaps [aabb1 aabb2]
  ;; (print (inspect (lume.first _G.tris)))
  ;; (print (inspect aabb1))
  ;; (print (inspect aabb2))
  (when (or (< aabb1.max.x aabb2.min.x)
            (> aabb1.min.x aabb2.max.x))
    (lua "return false"))
  (when (or (< aabb1.max.y aabb2.min.y)
            (> aabb1.min.y aabb2.max.y))
    (lua "return false"))
  true)

(fn _G.physics.collision-detection-and-resolution [ball]
  (local broad-phase-collisions [])
  (local ball-aabb (_G.physics.sphere-aabb ball))
  (each [_ [tri aabb] (ipairs _G.tris)]
    (when (_G.physics.aabb-overlaps ball-aabb aabb)
      (table.insert broad-phase-collisions tri)))

  (each [_ tri (ipairs broad-phase-collisions)]
    ;; (print (inspect tri))
    (let [collision (_G.physics.collision-sphere-tri ball tri)]
      (when (and collision (< (_G.vector.length collision.mtv) 0.5))
        ;; (love.graphics.print "Collision!")
        (let [
              n (_G.vector.normalize collision.mtv)
              d (_G.vector.dot _G.ball.velocity n)
              perpendicular-component (_G.vector.scale n d)
              parallel-component (_G.vector.subtract ball.velocity perpendicular-component)
              response (_G.vector.add
                        parallel-component
                        (_G.vector.scale perpendicular-component (- _G.elasticity)))]
          (set ball.position (_G.vector.add ball.position collision.mtv))
          (set ball.velocity response)))))
  (each [_ edge (ipairs (_G.geometry.tri-edges broad-phase-collisions))]
    (let [collision (_G.physics.collision-sphere-line ball edge)]
      (when collision
        ;; (love.graphics.print "Collision!")
        (let [
              n (_G.vector.normalize collision.mtv)
              d (_G.vector.dot _G.ball.velocity n)
              perpendicular-component (_G.vector.scale n d)
              parallel-component (_G.vector.subtract ball.velocity perpendicular-component)
              response (_G.vector.add
                        parallel-component
                        (_G.vector.scale perpendicular-component (- _G.elasticity)))]
          (set ball.position (_G.vector.add ball.position collision.mtv))
          (set ball.velocity response)))))
  (each [_ vert (ipairs (_G.geometry.tri-verts broad-phase-collisions))]
    (let [collision (_G.physics.collision-sphere-point ball vert)]
      (when collision
        ;; (love.graphics.print "Collision!")
        (let [
              n (_G.vector.normalize collision.mtv)
              d (_G.vector.dot _G.ball.velocity n)
              perpendicular-component (_G.vector.scale n d)
              parallel-component (_G.vector.subtract ball.velocity perpendicular-component)
              response (_G.vector.add
                        parallel-component
                        (_G.vector.scale perpendicular-component (- _G.elasticity)))]
          (set ball.position (_G.vector.add ball.position collision.mtv))
          (set ball.velocity response))))))

