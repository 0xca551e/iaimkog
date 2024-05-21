(set _G.camera {:x 0 :y 0})

(fn _G.camera.to-ball []
  (let [[bx by] (_G.geometry.to-isometric _G.ball.position.x _G.ball.position.y _G.ball.position.z)
        width (/ (love.graphics.getWidth) _G.scale)
        height (/ (love.graphics.getHeight) _G.scale)
        x (- bx (/ width 2))
        y (- by (/ height 2))]
    (set _G.camera.x (- x))
    (set _G.camera.y (- y))))
(comment
 (_G.camera.to-ball))
