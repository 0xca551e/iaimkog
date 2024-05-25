(set _G.generate-ball-preview1 (
  coroutine.create
  (fn []
    (local accuracy 0.5)
    (while true
      (when _G.requested-fast-preview
        (set _G.requested-fast-preview false)
        (set _G.ball-preview [])
        (set _G.ball-shadow-preview [])
        (var preview-ball {:position _G.ball.position
                          :velocity (_G.shot.velocity-vector _G.shot.type _G.shot.angle 1)
                          :radius _G.ball.radius
                          :collided false
                          :just-collided false
                          :spin-x _G.shot.spin-x
                          :spin-y _G.shot.spin-y})
        (for [i 0 (if (= _G.shot.type "roll") (* 70 accuracy) (* 210 accuracy)) 1]
          (when (= (% i 10) 0)
            (coroutine.yield))
          (_G.physics.integrate-ball preview-ball (/ _G.timestep accuracy))
          (when (< preview-ball.position.z -1)
            (lua :break))
          (let [{:x x :y y :z z} preview-ball.position
                [ix iy] (_G.geometry.to-isometric x y z)]
            (_G.util.concat-mut _G.ball-preview [(+ ix) (+ iy _G.ball.draw-offset.y 16)])))
        (_G.camera.to-preview-tail))
      (coroutine.yield)))))

(set _G.generate-ball-preview2 (
  coroutine.create
  (fn []
    (while true
      (when _G.requested-full-preview
        (set _G.requested-full-preview false)
        (set _G.ball-preview [])
        (set _G.ball-shadow-preview [])
        (var preview-ball {:position _G.ball.position
                          :velocity (_G.shot.velocity-vector _G.shot.type _G.shot.angle 1)
                          :radius _G.ball.radius
                          :collided false
                          :just-collided false
                          :spin-x _G.shot.spin-x
                          :spin-y _G.shot.spin-y})
        (for [i 0 (if (= _G.shot.type "roll") 70 210) 1]
          (when (= (% i 10) 0)
            (coroutine.yield))
          (_G.physics.integrate-ball preview-ball _G.timestep)
          (when (< preview-ball.position.z -1)
            (lua :break))
          (let [{:x x :y y :z z} preview-ball.position
                tile-z (?. _G.height-map (.. (math.floor x) "," (math.floor y)))
                [ix iy] (_G.geometry.to-isometric x y z)
                [isx isy] (_G.geometry.to-isometric x y (+ 1 0.25 (or tile-z 0)))]
            (_G.util.concat-mut _G.ball-preview [(+ ix) (+ iy _G.ball.draw-offset.y 16)])
            (_G.util.concat-mut _G.ball-shadow-preview [(+ isx) (+ isy _G.ball.draw-offset.y 16)])))
        (_G.camera.to-preview-tail))
      (coroutine.yield)))))
(comment
 (_G.generate-ball-preview))