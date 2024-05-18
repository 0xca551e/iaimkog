(require-macros :macros)

(local vector (require :vector))
(local physics (require :physics))
(local inspect (require :inspect))

(fn _G.translate-tri [tri d]
  {:a (vector.add tri.a d)
   :b (vector.add tri.b d)
   :c (vector.add tri.c d)})
(comment
 (_G.translate-tri {:a {:x 0 :y 0 :z 0}
                 :b {:x 0 :y 1 :z 0}
                 :c {:x 1 :y 0 :z 0}}
                {:x 2 :y 2 :z 2}))

(var lines [])
(fn love.handlers.stdin [line]
  ;; evaluate lines read from stdin as fennel code
  ;; note: for multi-line evaluating, we must not evaluate until the statement is complete.
  ;; we mark the end of a statement with a semicolon (for now, i'm too lazy to count brackets)
  (let [is-end-statement (line:match ";END%s*$")
        formatted-line (line:gsub ";END%s*$" "")]
    (table.insert lines formatted-line)
    (when is-end-statement
      (let [(ok val) (pcall fennel.eval (.. "(require-macros :macros)\n" (table.concat lines "\n")))]
        (print (if ok (fennel.view val) val)))
      (set lines []))))

fn love.load []
;; start a thread listening on stdin
(: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

(love.graphics.setDefaultFilter "nearest" "nearest")
(set _G.tris [])
(set _G.tiles [])
(set _G.slopes-dl [])

(set _G.test-tri {:a {:x 1 :y 0 :z 0}
                  :b {:x 2 :y 1 :z 0}
                  :c {:x 1 :y 1 :z 0}})
(set _G.ball {:position {:x 10.5 :y -4 :z 0.5}
              :radius 0.5
              :velocity {:x 0 :y 0 :z 0}})
(set _G.scale 3)
(set _G.grid-size 16)
(set _G.tile-width 28)
(set _G.tile-height 14)
(set _G.sprite-sheet (love.graphics.newImage "Sprite-0001.png"))
(set _G.sprite-quads
     {:ball (love.graphics.newQuad (* _G.grid-size 2) 0 _G.grid-size _G.grid-size (_G.sprite-sheet:getDimensions))
      :floor (love.graphics.newQuad 0 0 (* _G.grid-size 2) _G.grid-size (_G.sprite-sheet:getDimensions))
      :slope-dl (love.graphics.newQuad 48 0 32 24 (_G.sprite-sheet:getDimensions))})
(set _G.tile-hitboxes
     {:floor (_G.rect-tris vector.zero
                           {:x 1 :y 0 :z 0}
                           {:x 0 :y 1 :z 0}
                           {:x 1 :y 1 :z 0})
      :slope-dl (_G.rect-tris vector.zero
                              {:x 1 :y 0 :z (- 0 0.01)}
                              {:x 0 :y 1 :z (- -1 0.01)}
                              {:x 1 :y 1 :z (- -1 0.01)})})
(set _G.gravity 0.2)
(set _G.friction 1)
(set _G.elasticity 0.8)

(_G.make-floor 10 -5 0)
(_G.make-floor 10 -4 0)
(_G.make-floor 10 -3 0)
(_G.make-floor 10 -2 0)
(_G.make-floor 10 -1 0)
(_G.make-floor 10 0 0)
(_G.make-floor 11 0 0)
(_G.make-floor 12 0 0)
(_G.make-floor 13 0 0)
(_G.make-floor 14 0 -4)
(_G.make-floor 13 1 -4)
;; (_G.make-floor 3 1 0)
;; (_G.make-floor 3 2 0)
;; (_G.make-floor 3 3 0)
;; (_G.make-floor 3 3 1)
;; (_G.make-floor 3 3 2)
;; (_G.make-floor 3 3 3)

(_G.make-slope 10 1 0)
(_G.make-slope 10 2 -1)
(_G.make-slope 10 3 -2)
(_G.make-slope 10 4 -3)
(_G.make-slope 10 5 -4)

(_G.make-floor 10 6 -5)
(_G.make-floor 10 7 -5)
(_G.make-floor 10 8 -5)
(_G.make-floor 10 9 -5)


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
  (lume2.concat-mut _G.tris
                    (lume.map _G.tile-hitboxes.floor
                              (fn [tri]
                                (_G.translate-tri tri {:x x :y y :z z}))))
  (table.insert _G.tiles {:x x :y y :z z}))

(fn _G.make-slope [x y z]
  (lume2.concat-mut _G.tris
                    (lume.map _G.tile-hitboxes.slope-dl
                              (fn [tri]
                                (_G.translate-tri tri {:x x :y y :z z}))))
  (table.insert _G.slopes-dl {:x x :y y :z z}))

(fn _G.draw-floor [x y z]
  (let [[ix iy] (_G.to-isometric x y z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "floor") (- ix _G.grid-size) iy)))

(fn _G.draw-slopes [x y z]
  (let [[ix iy] (_G.to-isometric x y z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "slope-dl") (- ix _G.grid-size) iy)))

(fn _G.draw-ball []
  (let [[ix iy] (_G.to-isometric _G.ball.position.x _G.ball.position.y _G.ball.position.z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "ball") (- ix 8) (- iy 10))))

(fn _G.integrate-ball [dt]
  (set _G.ball.velocity (-> _G.ball.velocity
                         (vector.scale (/ 1 (+ 1 (* dt _G.friction))))))
  (+= _G.ball.velocity.z (- _G.gravity))
  (set _G.ball.position (-> _G.ball.velocity
                         (vector.scale dt)
                         (vector.add _G.ball.position))))

(fn _G.manual-control-ball [dt]
  (let [d (* 5 dt)
        control _G.ball.velocity]
    (when (love.keyboard.isDown "w") (-= control.y d))
    (when (love.keyboard.isDown "a") (-= control.x d))
    (when (love.keyboard.isDown "s") (+= control.y d))
    (when (love.keyboard.isDown "d") (+= control.x d))
    (when (love.keyboard.isDown "space") (+= control.z d))
    (when (love.keyboard.isDown "lshift") (-= control.z d))))

(fn love.update [dt]
  (_G.integrate-ball dt)
  (_G.manual-control-ball dt))

;; (fn _G.project-point-plane [p n o]
;;   (let [d (physics.distance-plane-point-normal p n o)]
;;     (-> n
;;         (_G.vector.scale (- d))
;;         (_G.vector.add p))))
;; (comment
;;  (_G.project-point-plane {:x 3 :y 3 :z 100} {:x 0 :y 0 :z 1} {:x 0 :y 0 :z 0})
;;  (_G.project-point-plane {:x 3 :y 3 :z -100} {:x 0 :y 0 :z 1} {:x 0 :y 0 :z 0}))


(fn love.draw []
  (love.graphics.scale _G.scale)
  (each [_ v (ipairs _G.tiles)]
    (_G.draw-floor v.x v.y v.z))
  (each [_ v (ipairs _G.slopes-dl)]
    (_G.draw-slopes v.x v.y v.z))
  (_G.draw-ball)

  (each [_ tri (ipairs _G.tris)]
    (let [collision (physics.collision-sphere-tri _G.ball tri)]
      (when collision
        (love.graphics.print "Collision!")
        (set _G.ball.position (vector.add _G.ball.position collision.mtv))
        (let [
              ;; dot the velocity vector along the normal'
              ;; when you scale the normal with the dot product, you get the perpendicular component.
              n (vector.normalize collision.mtv)
              d (vector.dot _G.ball.velocity n)
              perpendicular-component (vector.scale n d)
              parallel-component (vector.subtract _G.ball.velocity perpendicular-component)
              response (vector.add
                        parallel-component
                        (vector.scale perpendicular-component (- _G.elasticity)))]
          ;; (love.graphics.print (inspect n) 10 100)
          ;; (love.graphics.print (inspect d) 10 80)
          (set _G.ball.velocity response)
          (love.graphics.print (inspect response) 10 100))
        ;; (set _G.ball.velocity vector.zero)
        ;; (set _G.ball.velocity (vector.reflect _G.ball.velocity (physics.tri-normal tri)))
        (comment
         (let [n (-> collision.mtv (vector.normalize) (vector.invert))
               d (vector.dot _G.ball.velocity n)
               projected (vector.scale n d)
               to-subtract (vector.scale projected _G.elasticity)]
           (set _G.ball.velocity (vector.subtract _G.ball.velocity to-subtract))))))))

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  )

