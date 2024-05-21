(require-macros :macros)

(love.graphics.setDefaultFilter "nearest" "nearest")

(require :vector)
(require :physics)
(require :geometry)
(require :util)
(require :level)
(require :shot)

(set _G.camera {:x 0 :y 0})

(set _G.control-map {:left "left"
                  :right "right"
                  :up "up"
                  :down "down"
                  :fine-tune "lshift"
                  :secondary "z"
                  :primary "x"
                  :tertiary "c"})

(set _G.just-pressed {})

(fn _G.triangle-oscillate [t]
  (if (<= t 0.5)
      (-> t (* 2))
      (-> t (- 1) (* (- 1)) (* 2))))

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

(set _G.ball-preview [])
(fn _G.generate-ball-preview []
  (set _G.ball-preview [])
  (local dt (/ 1 60))
  (local preview-ball {:position _G.ball.position :velocity (_G.shot.velocity-vector _G.shot.type _G.shot.angle 1) :radius _G.ball.radius})
  (for [i 0 400 1]
    (_G.integrate-ball2 preview-ball dt)
    (let [{:x x :y y :z z} preview-ball.position
          iso-coords (_G.geometry.to-isometric x y z)]
      (_G.util.concat-mut _G.ball-preview iso-coords))))
(comment
 (_G.generate-ball-preview))

(fn _G.camera-to-ball []
  (let [[bx by] (_G.geometry.to-isometric _G.ball.position.x _G.ball.position.y _G.ball.position.z)
        width (/ (love.graphics.getWidth) _G.scale)
        height (/ (love.graphics.getHeight) _G.scale)
        x (- bx (/ width 2))
        y (- by (/ height 2))]
    (set _G.camera.x (- x))
    (set _G.camera.y (- y))))
(comment
 (_G.camera-to-ball))

(fn love.load []
  (love.window.setMode 720 480)
  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (set _G.paused false)

  (set _G.tris [])

  (set _G.ball {:position {:x 10.5 :y -4 :z 2.25}
             :radius 0.25
             :velocity {:x 0 :y 3 :z 0}
             :variant :ball})
  (set _G.drawables [_G.ball])

  (set _G.scale 3)
  (set _G.grid-size 16)
  (set _G.tile-width 32)
  (set _G.tile-height 16)
  (set _G.gravity 0.2)
  (set _G.friction 0.5)
  (set _G.elasticity 0.8)

  (for [i -20 20 1]
    (for [j -20 20 1]
      (_G.level.make-tile :floor i j 0)))
  ;; NOTE: the level is static, so we don't need to sort every frame.
  ;; in a later version this might change
  (_G.util.insertion-sort-by-mut _G.tris (fn [a b]
                                (let [[tri-a aabb-a] a
                                      [tri-b aabb-b] b]
                                  (- aabb-a.min.x aabb-b.min.x))))
  )

;; TODO: replace integrate-ball if this works out
(fn _G.integrate-ball2 [ball dt]
  (set ball.velocity (-> ball.velocity
                         (_G.vector.scale (/ 1 (+ 1 (* dt _G.friction))))))
  (+= ball.velocity.z (- _G.gravity))
  (set ball.position (-> ball.velocity
                         (_G.vector.scale dt)
                         (_G.vector.add ball.position)))
  (_G.physics.collision-detection-and-resolution ball))

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
    (_G.shot.update dt)))

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
  (when (= _G.shot.state "moving")
    (_G.camera-to-ball))
  (love.graphics.translate _G.camera.x _G.camera.y)
  (love.graphics.print (inspect _G.just-pressed))

  (_G.level.draw)

  (when (and (= _G.shot.state "aiming") (>= (# _G.ball-preview) 2))
    (_G.generate-ball-preview)
    (love.graphics.line (unpack _G.ball-preview)))

  (love.graphics.origin)
  (_G.shot.draw (love.timer.getDelta))
  
  (lume.clear _G.just-pressed))

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  (tset _G.just-pressed scancode true)
  ;; (when (= scancode "tab")
  ;;   (set _G.paused (not _G.paused)))
  ;; (when _G.paused
  ;;   (_G.integrate-ball (love.timer.getDelta)))
  )
