(fn _G.linear [x]
  x)
(fn _G.ease-in-out-cubic [x]
  (if (< x 0.5) (* (* (* 4 x) x) x)
      (- 1 (/ (math.pow (+ (* (- 2) x) 2) 3) 2))))
(fn _G.ease-out-quint [x]
  (- 1 (math.pow (- 1 x) 5)))

(set _G.camera {:x 0 :y 0 :target {:from {:x 0 :y 0}
                                   :to {:x 0 :y 0}
                                   :duration 0
                                   :t 1
                                   :easing _G.linear}})

(fn _G.camera.set-target [x y duration easing]
  (tset _G.camera :target {:from {:x _G.camera.x :y _G.camera.y}
                           :to {:x x :y y}
                           :duration duration
                           :t 0
                           :easing easing})
                                        ;(print (inspect _G.camera))
  )

(fn _G.camera.to-ball []
  (let [target-pos (_G.vector.add _G.ball.position (-> _G.ball.velocity (_G.vector.scale 2)))
        [bx by] (_G.geometry.to-isometric target-pos.x target-pos.y target-pos.z)
        width (/ (love.graphics.getWidth) _G.scale)
        height (/ (love.graphics.getHeight) _G.scale)
        x (- bx (/ width 2))
        y (- by (/ height 2))]
    (_G.camera.set-target (- x) (- y) 0.5 _G.linear)))
(comment
 (_G.camera.to-ball))

(fn _G.camera.to-preview-tail []
  (let [preview-length (# _G.ball-preview)
        tail-x (. _G.ball-preview (- preview-length 1))
        tail-y (. _G.ball-preview preview-length)
        width (/ (love.graphics.getWidth) 3)
        height (/ (love.graphics.getHeight) 3)
        centered-tail-x (- tail-x (/ width 2))
        centered-tail-y (- tail-y (/ height 2))
        [ball-x ball-y] (_G.geometry.to-isometric _G.ball.position.x _G.ball.position.y _G.ball.position.z)
        centered-ball-x (- ball-x (/ width 2))
        centered-ball-y (- ball-y (/ height 2))
        new-pos (_G.vector.move-towards {:x centered-tail-x :y centered-tail-y :z 0} {:x centered-ball-x :y centered-ball-y :z 0} (/ height 2))]
    (_G.camera.set-target (- new-pos.x) (- new-pos.y) 1 _G.ease-out-quint)))

(fn _G.camera.lerp-to-target [dt]
  (let [t-delta (/ dt _G.camera.target.duration)
        next-t (math.min (+ _G.camera.target.t t-delta) 1)
        eased-t (lume.lerp 0 1 (_G.camera.target.easing next-t))
        next-x (lume.lerp _G.camera.target.from.x _G.camera.target.to.x eased-t)
        next-y (lume.lerp _G.camera.target.from.y _G.camera.target.to.y eased-t)]
    (tset _G.camera.target :t next-t)
    (tset _G.camera :x next-x)
    (tset _G.camera :y next-y)))

true