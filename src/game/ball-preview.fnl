(fn _G.generate-ball-preview []
  (set _G.ball-preview [])
  (var preview-ball {:position _G.ball.position
                     :velocity (_G.shot.velocity-vector _G.shot.type _G.shot.angle 1)
                     :radius _G.ball.radius
                     :collided false
                     :just-collided false
                     :spin-x _G.shot.spin-x})
  (for [i 0 200 1]
    (_G.physics.integrate-ball preview-ball _G.timestep)
    (when (< preview-ball.position.z -1)
      (lua :break))
    (let [{:x x :y y :z z} preview-ball.position
          [ix iy] (_G.geometry.to-isometric x y z)]
      (_G.util.concat-mut _G.ball-preview [(+ ix) (+ iy _G.ball.draw-offset.y 16)]))))
(comment
 (_G.generate-ball-preview))