(require-macros :macros)

(require :vector)
(require :physics)
(require :geometry)
(require :util)
(require :level)

(set _G.control-map {:left "left"
                  :right "right"
                  :up "up"
                  :down "down"
                  :fine-tune "lshift"
                  :secondary "z"
                  :primary "x"})

(set _G.just-pressed {})
(set _G.shot-angle 0) ; in radians
(set _G.spin-x 0) ; -1 to 1
(set _G.spin-y 0) ; -1 to 1
(set _G.shot-type "roll") ; roll, roll2, fly
(set _G.shot-state "aiming") ; (DAG) aiming -> (preshot-fly | preshot-normal) -> charging -> moving
(set _G.shot-meter-timer 0)
(set _G.shot-meter 0) ; 0 to 1
(set _G.fly-meter 0) ; -1 to 1
(set _G.stillness-timer 0)

(set _G.shot-map {:roll {:up "fly" :down "roll2"}
               :roll2 {:up "roll" :down "roll2"}
               :fly {:up "fly" :down "roll"}})

(fn _G.shot-change-type [d]
  (set _G.shot-type (. _G.shot-map _G.shot-type d))
  (when (not= _G.shot-type "fly")
    (set _G.spin-x 0)
    (set _G.spin-y 0)))

(fn _G.shot-handle-controls [dt]
  (case _G.shot-state
    "aiming" (do
               (let [shift-factor (if (love.keyboard.isDown (. _G.control-map :fine-tune)) 0.5 1)
                     speed (* shift-factor 3 dt)
                     spin-speed (* shift-factor 1 dt)]
                 (if (love.keyboard.isDown (. _G.control-map :secondary))
                     (do
                       (when (love.keyboard.isDown (. _G.control-map :left))
                         (set _G.spin-x (lume.clamp (- _G.spin-x spin-speed) (- 1) 1)))
                       (when (love.keyboard.isDown (. _G.control-map :right))
                         (set _G.spin-x (lume.clamp (+ _G.spin-x spin-speed) (- 1) 1)))
                       (when (love.keyboard.isDown (. _G.control-map :up))
                         (set _G.spin-y (lume.clamp (- _G.spin-y spin-speed) (- 1) 1)))
                       (when (love.keyboard.isDown (. _G.control-map :down))
                         (set _G.spin-y (lume.clamp (+ _G.spin-y spin-speed) (- 1) 1))))
                     (do
                       (when (love.keyboard.isDown (. _G.control-map :left))
                         (+= _G.shot-angle speed)
                         (%= _G.shot-angle (* 2 math.pi)))
                       (when (love.keyboard.isDown (. _G.control-map :right))
                         (-= _G.shot-angle speed)
                         (%= _G.shot-angle (* 2 math.pi)))
                       (when (. _G.just-pressed (. _G.control-map :up))
                         (_G.shot-change-type "up"))
                       (when (. _G.just-pressed (. _G.control-map :down))
                         (_G.shot-change-type "down"))))
                 (when (love.keyboard.isDown (. _G.control-map :primary))
                   (if (= _G.shot-type "fly")
                       (set _G.shot-state "preshot-fly")
                       (set _G.shot-state "preshot-normal")))))
    "preshot-fly" (do
                    (when (. _G.just-pressed (. _G.control-map :secondary))
                      (set _G.shot-state "aiming"))
                    (when (. _G.just-pressed (. _G.control-map :primary))
                      ;; (tset _G.just-pressed (. _G.control-map :primary) nil)
                      (set _G.shot-state "charging")))
    "preshot-normal" (do
                       (when (love.keyboard.isDown (. _G.control-map :secondary))
                         (set _G.shot-state "aiming"))
                       (when (. _G.just-pressed (. _G.control-map :primary))
                         (set _G.shot-state "charging")))
    "charging" (when (. _G.just-pressed (. _G.control-map :primary))
                 (_G.apply-shot))
    "moving" (do (todo!))))

(fn _G.apply-shot []
  (set _G.shot-state "moving")
  (set _G.stillness-timer 0)
  (let [base-vector (if (= _G.shot-type "fly") (_G.vector.normalize {:x 1 :y 0 :z 1}) {:x 1 :y 0 :z 0})
        velocity (-> base-vector
                     (_G.vector.rotate-by-axis-angle {:x 0 :y 0 :z 1} _G.shot-angle)
                     (_G.vector.scale (* _G.shot-meter 10)))]
    (set _G.ball.velocity velocity)))

(fn _G.conclude-shot []
  (set _G.shot-angle 0)
  (set _G.spin-x 0)
  (set _G.spin-y 0)
  (set _G.shot-type "roll")
  (set _G.shot-state "aiming")
  (set _G.shot-meter-timer 0)
  (set _G.shot-meter 0)
  (set _G.fly-meter 0)
  (set _G.stillness-timer 0))

(fn _G.triangle-oscillate [t]
  (if (<= t 0.5)
      (-> t (* 2))
      (-> t (- 1) (* (- 1)) (* 2))))

(fn _G.shot-update [dt]
  (_G.shot-handle-controls dt)
  (case _G.shot-state
    "preshot-fly" (let [time (love.timer.getTime)
                        speed 1
                        fly-level (-> (_G.triangle-oscillate (% (* time speed) 1)) (* 2) (- 1))]
                    (set _G.fly-meter fly-level)
                    (print fly-level))
    "charging" (do
                 (+= _G.shot-meter-timer dt)
                 (if (> _G.shot-meter-timer 2)
                     (do
                       (set _G.shot-meter 0.1)
                       (_G.apply-shot))
                     (do
                       (set _G.shot-meter (_G.triangle-oscillate (/ _G.shot-meter-timer 2)))
                       (print _G.shot-meter))))
    "moving" (do
               ;; (print "moving?")
               (_G.integrate-ball dt)
               (when (< (_G.vector.length-sq _G.ball.velocity) 0.02)
                 (+= _G.stillness-timer dt)
                 (when (> _G.stillness-timer 3)
                   (_G.conclude-shot))))))

(fn _G.shot-draw []
  (love.graphics.print
   (table.concat [_G.shot-state _G.shot-angle _G.shot-type _G.shot-state _G.spin-x _G.spin-y] "\n")
   10 10))

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

(fn love.load []
  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (love.graphics.setDefaultFilter "nearest" "nearest")
  (set _G.paused false)

  (set _G.tris [])
  (set _G.edges [])
  (set _G.verts [])

  (set _G.tiles [])
  (set _G.slopes-dl [])
  (set _G.hole-tiles [])

  (set _G.test-tri {:a {:x 1 :y 0 :z 0}
                    :b {:x 2 :y 1 :z 0}
                    :c {:x 1 :y 1 :z 0}})
  (set _G.ball {:position {:x 10.5 :y -4 :z 0.25}
                :radius 0.25
                :velocity {:x 0 :y 3 :z 0}})
  (set _G.scale 3)
  (set _G.grid-size 16)
  (set _G.tile-width 32)
  (set _G.tile-height 16)
  (set _G.sprite-sheet (love.graphics.newImage "Sprite-0001.png"))
  (set _G.sprite-quads
       {:ball (love.graphics.newQuad (* _G.grid-size 2) 0 _G.grid-size _G.grid-size (_G.sprite-sheet:getDimensions))
        :floor (love.graphics.newQuad 0 0 (* _G.grid-size 2) (* _G.grid-size 2) (_G.sprite-sheet:getDimensions))
        :slope-dl (love.graphics.newQuad 48 0 32 48 (_G.sprite-sheet:getDimensions))
        :hole-tile (love.graphics.newQuad 0 32 (* _G.grid-size 2) (* _G.grid-size 2) (_G.sprite-sheet:getDimensions))})
  (set _G.tile-hitboxes
       {:floor (_G._G.level.generate-hitboxes (_G.geometry.rect-tris _G.vector.zero
                                                   {:x 1 :y 0 :z 0}
                                                   {:x 0 :y 1 :z 0}
                                                   {:x 1 :y 1 :z 0}))
        :slope-dl (_G._G.level.generate-hitboxes (_G.geometry.rect-tris _G.vector.zero
                                                      {:x 1 :y 0 :z 0}
                                                      {:x 0 :y 1 :z -1}
                                                      {:x 1 :y 1 :z -1}))
        :floor-with-hole (_G.level.tile-with-hole _G.vector.zero)})
  (set _G.gravity 0.2)
  (set _G.friction 1)
  (set _G.elasticity 0.8)

  (_G.level.make-floor 10 -5 0)
  (_G.level.make-floor 10 -4 0)
  (_G.level.make-floor 10 -3 0)
  (_G.level.make-floor 10 -2 0)
  (_G.level.make-floor 10 -1 0)
  (_G.level.make-floor 10 0 0)
  (_G.level.make-floor 11 0 0)
  (_G.level.make-floor 12 0 0)
  (_G.level.make-hole 13 0 0)
  ;; (_G.level.make-floor 14 0 -4)
  ;; (_G.level.make-floor 13 1 -4)
  ;; (_G.level.make-floor 3 1 0)
  ;; (_G.level.make-floor 3 2 0)
  ;; (_G.level.make-floor 3 3 0)
  ;; (_G.level.make-floor 3 3 1)
  ;; (_G.level.make-floor 3 3 2)
  ;; (_G.level.make-floor 3 3 3)

  (_G.level.make-slope 10 1 0)
  (_G.level.make-slope 10 2 -1)
  (_G.level.make-slope 10 3 -2)
  (_G.level.make-slope 10 4 -3)
  (_G.level.make-slope 10 5 -4)

  (_G.level.make-floor 10 6 -5)
  (_G.level.make-floor 10 7 -5)
  (_G.level.make-floor 10 8 -5)
  (_G.level.make-floor 10 9 -5)
  )

(fn _G.integrate-ball [dt]
  (set _G.ball.velocity (-> _G.ball.velocity
                         (_G.vector.scale (/ 1 (+ 1 (* dt _G.friction))))))
  (+= _G.ball.velocity.z (- _G.gravity))
  (set _G.ball.position (-> _G.ball.velocity
                         (_G.vector.scale dt)
                         (_G.vector.add _G.ball.position))))

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
  (when (not _G.paused)
    ;; (_G.integrate-ball dt)
    ;; (_G.manual-control-ball dt)
    (_G.shot-update dt)))

;; (fn _G.project-point-plane [p n o]
;;   (let [d (_G.physics.distance-plane-point-normal p n o)]
;;     (-> n
;;         (_G._G.vector.scale (- d))
;;         (_G._G.vector.add p))))
;; (comment
;;  (_G.project-point-plane {:x 3 :y 3 :z 100} {:x 0 :y 0 :z 1} {:x 0 :y 0 :z 0})
;;  (_G.project-point-plane {:x 3 :y 3 :z -100} {:x 0 :y 0 :z 1} {:x 0 :y 0 :z 0}))

(fn love.draw []
  (love.graphics.scale _G.scale)
  (love.graphics.print (inspect _G.just-pressed))
  (_G.shot-draw (love.timer.getDelta))
  
  (each [_ v (ipairs _G.tiles)]
    (_G.level.draw-floor v.x v.y v.z))
  (each [_ v (ipairs _G.slopes-dl)]
    (_G.level.draw-slopes v.x v.y v.z))
  (each [_ v (ipairs _G.hole-tiles)]
    (_G.level.draw-hole v.x v.y v.z))
  (_G.level.draw-ball)

  (each [_ tri (ipairs _G.tris)]
    (let [collision (_G.physics.collision-sphere-tri _G.ball tri)]
      (when (and collision (< (_G.vector.length collision.mtv) 0.5))
        ;; (love.graphics.print "Collision!")
        (let [
              n (_G.vector.normalize collision.mtv)
              d (_G.vector.dot _G.ball.velocity n)
              perpendicular-component (_G.vector.scale n d)
              parallel-component (_G.vector.subtract _G.ball.velocity perpendicular-component)
              response (_G.vector.add
                        parallel-component
                        (_G.vector.scale perpendicular-component (- _G.elasticity)))]
          (set _G.ball.position (_G.vector.add _G.ball.position collision.mtv))
          (set _G.ball.velocity response)))))

  (each [_ edge (ipairs _G.edges)]
    (let [collision (_G.physics.collision-sphere-line _G.ball edge)]
      (when collision
        ;; (love.graphics.print "Collision (Edge)!")
        (let [
              n (_G.vector.normalize collision.mtv)
              d (_G.vector.dot _G.ball.velocity n)
              perpendicular-component (_G.vector.scale n d)
              parallel-component (_G.vector.subtract _G.ball.velocity perpendicular-component)
              response (_G.vector.add
                        parallel-component
                        (_G.vector.scale perpendicular-component (- _G.elasticity)))]
          (set _G.ball.position (_G.vector.add _G.ball.position collision.mtv))
          (set _G.ball.velocity response)))))

  (each [_ vert (ipairs _G.verts)]
    (let [collision (_G.physics.collision-sphere-point _G.ball vert)]
      (when collision
        ;; (love.graphics.print "Collision (Vert)!")
        (let [
              n (_G.vector.normalize collision.mtv)
              d (_G.vector.dot _G.ball.velocity n)
              perpendicular-component (_G.vector.scale n d)
              parallel-component (_G.vector.subtract _G.ball.velocity perpendicular-component)
              response (_G.vector.add
                        parallel-component
                        (_G.vector.scale perpendicular-component (- _G.elasticity)))]
          (set _G.ball.position (_G.vector.add _G.ball.position collision.mtv))
          (set _G.ball.velocity response)))))
  
  (lume.clear _G.just-pressed))

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  (tset _G.just-pressed scancode true)
  ;; (when (= scancode "tab")
  ;;   (set _G.paused (not _G.paused)))
  ;; (when _G.paused
  ;;   (_G.integrate-ball (love.timer.getDelta)))
  )

