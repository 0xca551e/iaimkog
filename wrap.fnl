(require-macros :macros)

(require :vector)
(require :physics)
(require :geometry)
(require :util)
(require :level)

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
  (set _G.paused true)

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
                :velocity {:x 0 :y 6 :z 0}})
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
    (_G.integrate-ball dt)
    (_G.manual-control-ball dt)))

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
        (love.graphics.print "Collision!")
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
        (love.graphics.print "Collision (Edge)!")
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
        (love.graphics.print "Collision (Vert)!")
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
  )

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  (when (= scancode "tab")
      (set _G.paused (not _G.paused)))
  (when _G.paused
    (_G.integrate-ball (love.timer.getDelta))))

