(require-macros :macros)
;; (require :util)

(fn _G.project-point-plane [p n o]
  (let [d (_G.distance-plane-point-normal p n o)]
    (-> n
        (_G.vector.scale (- d))
        (_G.vector.add p))))
(comment
 (_G.project-point-plane {:x 3 :y 3 :z 100} {:x 0 :y 0 :z 1} {:x 0 :y 0 :z 0})
 (_G.project-point-plane {:x 3 :y 3 :z -100} {:x 0 :y 0 :z 1} {:x 0 :y 0 :z 0}))

(fn _G.vector-reflect [v n]
  (let [d (_G.vector.dot v n)
        projected-vector (_G.vector.scale n d)
        +2pv (_G.vector.scale projected-vector 2)]
    (_G.vector.subtract v +2pv)))
(comment
 (_G.vector-reflect {:x -3 :y 3 :z -1} {:x 0 :y 0 :z 1}))

(var lines [])
(fn love.handlers.stdin [line]
  ;; evaluate lines read from stdin as fennel code
  ;; note: for multi-line evaluating, we must not evaluate until the statement is complete.
  ;; we mark the end of a statement with a semicolon (for now, i'm too lazy to count brackets)
  (let [is-end-statement (line:match ";%s*$")
        formatted-line (line:gsub ";%s*$" "")]
    (table.insert lines formatted-line)
    (when is-end-statement
      (let [(ok val) (pcall fennel.eval (.. "(require-macros :macros)\n" (table.concat lines "\n")))]
        (print (if ok (fennel.view val) val)))
      (set lines []))))

(fn love.load []
  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (love.graphics.setDefaultFilter "nearest" "nearest")
  (set _G.tris [])
  (set _G.tiles [])

  (_G.make-floor 0 0 0)
  (_G.make-floor 1 0 0)
  (_G.make-floor 2 0 0)
  (_G.make-floor 3 0 0)
  (_G.make-floor 4 0 -4)
  (_G.make-floor 3 1 0)
  (_G.make-floor 3 2 0)
  (_G.make-floor 3 3 0)
  (_G.make-floor 3 3 1)
  (_G.make-floor 3 3 2)
  (_G.make-floor 3 3 3)

  (set _G.test-tri {:a {:x 1 :y 0 :z 0}
                    :b {:x 2 :y 1 :z 0}
                    :c {:x 1 :y 1 :z 0}})
  (set _G.vector (require :vector))
  (set _G.inspect (require :inspect))
  (set _G.ball {:position {:x 1 :y 0 :z 0.5}
                :radius 0.5
                :velocity {:x 0 :y 0 :z -1}})
  (set _G.scale 4)
  (set _G.grid-size 16)
  (set _G.tile-width 28)
  (set _G.tile-height 14)
  (set _G.sprite-sheet (love.graphics.newImage "Sprite-0001.png"))
  (set _G.sprite-quads
       {:ball (love.graphics.newQuad (* _G.grid-size 2) 0 _G.grid-size _G.grid-size (_G.sprite-sheet:getDimensions))
        :floor (love.graphics.newQuad 0 0 (* _G.grid-size 2) _G.grid-size (_G.sprite-sheet:getDimensions))})
  (set _G.gravity 0.2)
  (set _G.friction 1)
  )

(fn _G.to-isometric [x y z]
  (let [ix (/ (* (- x y) _G.tile-width) 2)
        iy (/ (* (- (+ x y) z) _G.tile-height) 2)]
    [ix iy]))

; a---b
; |   |
; c---d
;; TODO: make tris work counter-clockwise
(fn _G.rect-tris [a b c d]
  ;; [{:a a :b c :c b}
  ;;  {:a b :b c :c d}]
  [{:a a :b b :c c}
   {:a b :b d :c c}]
  )

(fn _G.make-floor [x y z]
  (let [a {:x x :y y :z z}
        b {:x (+ x 1) :y y :z z}
        c {:x x :y (+ y 1) :z z}
        d {:x (+ x 1) :y (+ y 1) :z z}]
    (lume2.concat-mut _G.tris (_G.rect-tris a b c d))
    (table.insert _G.tiles a)))

(fn _G.draw-floor [x y z]
  (let [[ix iy] (_G.to-isometric x y z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "floor") (- ix _G.grid-size) iy)))

(fn _G.draw-ball []
  (let [[ix iy] (_G.to-isometric _G.ball.position.x _G.ball.position.y _G.ball.position.z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "ball") (- ix 8) (- iy 10))))

(fn _G.integrate-ball [dt]
  (set _G.ball.velocity (-> _G.ball.velocity
                         (_G.vector.scale (/ 1 (+ 1 (* dt _G.friction))))))
  (+= _G.ball.velocity.z (- _G.gravity))
  (set _G.ball.position (-> _G.ball.velocity
                         (_G.vector.scale dt)
                         (_G.vector.add _G.ball.position))))

(fn _G.manual-control-ball [dt]
  (let [d (* 1 dt)]
    (when (love.keyboard.isDown "w") (-= _G.ball.position.y d))
    (when (love.keyboard.isDown "a") (-= _G.ball.position.x d))
    (when (love.keyboard.isDown "s") (+= _G.ball.position.y d))
    (when (love.keyboard.isDown "d") (+= _G.ball.position.x d))
    (when (love.keyboard.isDown "space") (+= _G.ball.position.z d))
    (when (love.keyboard.isDown "lshift") (-= _G.ball.position.z d))))

(fn love.update [dt]
  (_G.integrate-ball dt)
  (_G.manual-control-ball dt))

(fn love.draw []
  (love.graphics.scale _G.scale)
  (each [_ v (ipairs _G.tiles)]
    (_G.draw-floor v.x v.y v.z))
  (_G.draw-ball)

  (each [_ tri (ipairs _G.tris)]
    (let [collision (_G.collision-sphere-tri _G.ball tri)]
      (when collision
        (love.graphics.print "Collision!")
        (set _G.ball.position (_G.vector.add _G.ball.position collision.mtv))
        (set _G.ball.velocity (_G.vector-reflect _G.ball.velocity (_G.tri-normal tri)))))))

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  )


; (fn collision-sphere-sphere [a b]
;   (todo))

(fn _G.collision-sphere-point [s p]
  (let [direction (_G.vector.subtract p s.position)
        normal (_G.vector.normalize direction)
        len (_G.vector.length direction)
        penetration-depth (- s.radius len)]
    (if (> penetration-depth 0)
      {:mtv (-> normal (_G.vector.scale penetration-depth))
       :contact (-> normal (_G.vector.scale s.radius))}
      nil)))

(fn _G.point-lies-between [p a b]
  (let [n (-> (_G.vector.subtract a b))
        pd (_G.vector.dot p n)
        ad (_G.vector.dot a n)
        bd (_G.vector.dot b n)]
    (>or< ad pd bd)))

(fn _G.project-point-line-segment [p a b]
  (let [ap (_G.vector.subtract p a)
        ab (_G.vector.subtract b a)]
    (_G.vector.add a (_G.vector.scale ab (/ (_G.vector.dot ap ab) (_G.vector.dot ab ab))))))

(fn _G.collision-sphere-line [s l]
  (let [closest-point (_G.project-point-line-segment s.position (. l 1) (. l 2))]
    (if (_G.point-lies-between closest-point (. l 1) (. l 2))
      (_G.collision-sphere-point s closest-point)
      (do
        (var longest (- (/ 1 0)))
        (var worst-mtv nil)
        (each [k v (ipairs l)]
          (let [mtv (_G.collision-sphere-point s v)
                len (_G.vector.length-sq (or (and mtv mtv.mtv) _G.vector.zero))]
            (when (and mtv (> len longest))
              (set longest len)
              (set worst-mtv mtv))))
        worst-mtv))))

(fn _G.collision-point-tri-barycentric [p tri]
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

(fn _G.tri-normal [tri]
  (let [a (_G.vector.subtract tri.b tri.a)
        b (_G.vector.subtract tri.c tri.a)]
    (_G.vector.normalize {:x (- (* a.y b.z) (* a.z b.y))
                       :y (- (* a.z b.x) (* a.x b.z))
                       :z (- (* a.x b.y) (* a.y b.x))})))

(fn _G.distance-plane-point-normal [p n o]
  (-> p
    (_G.vector.subtract o)
    (_G.vector.dot n)))

(fn _G.nearest-point-sphere-normal [s n]
  (-> n (_G.vector.scale (- s.radius)) (_G.vector.add s.position)))

;; TODO: collision should work on triangles that wind counter clockwise, not clockwise
(fn _G.collision-sphere-tri [s t]
  (let [point-in-tri (_G.collision-point-tri-barycentric s.position t)
        normal (_G.tri-normal t)
        nearest (_G.nearest-point-sphere-normal s normal)
        penetration-depth (- (_G.distance-plane-point-normal nearest normal t.a))]
    (if (and point-in-tri (> penetration-depth 0))
        {:mtv (_G.vector.scale normal penetration-depth)}
        (comment
         (do
           (var longest (- (/ 1 0)))
           (var worst-mtv nil)
                                        ; TODO: i think triangles are better treated as arrays than tables
           (each [k v (lume.pairs-2-looped-window [t.a t.b t.c])]
             (let [mtv (_G.collision-sphere-line s v)
                   len (_G.vector.length-sq (or (and mtv mtv.mtv) _G.vector.zero))]
               (when (and mtv (> len longest))
                 (set longest len)
                 (set worst-mtv mtv))))
           worst-mtv)))))
