(require-macros :src.macros)

(set _G.shot {})

(set _G.shot.angle 0) ; in radians
(set _G.shot.spin-x 0) ; -1 to 1
(set _G.shot.spin-y 0) ; -1 to 1
(set _G.shot.type "roll") ; roll, roll2, fly
(set _G.shot.state "aiming") ; (DAG) aiming -> (preshot-fly | preshot-normal) -> charging -> moving
(set _G.shot.meter-timer 0)
(set _G.shot.meter 0) ; 0 to 1
(set _G.shot.fly-meter 0) ; -1 to 1
(set _G.shot.stillness-timer 0)

(set _G.shot.map {:roll {:up "fly" :down "roll2"}
               :roll2 {:up "roll" :down "roll2"}
               :fly {:up "fly" :down "roll"}})

(fn _G.shot.change-type [d]
  (set _G.shot.type (. _G.shot.map _G.shot.type d))
  (when (not= _G.shot.type "fly")
    (set _G.shot.spin-x 0)
    (set _G.shot.spin-y 0)))

(fn _G.shot.handle-controls [dt]
  (case _G.shot.state
    "aiming" (do
               (let [shift-factor (if (love.keyboard.isDown (. _G.control-map :fine-tune)) 0.5 1)
                     speed (* shift-factor 3 dt)
                     spin-speed (* shift-factor 1 dt)
                     camera-speed (* shift-factor (. _G.camera-speed))]
                 (if (love.keyboard.isDown (. _G.control-map :tertiary))
                     (do
                       (let [l (if (love.keyboard.isDown (. _G.control-map :left)) -1 0)
                             r (if (love.keyboard.isDown (. _G.control-map :right)) 1 0)
                             u (if (love.keyboard.isDown (. _G.control-map :up)) -1 0)
                             d (if (love.keyboard.isDown (. _G.control-map :down)) 1 0)
                             dx (* (+ l r) camera-speed)
                             dy (* (+ u d) camera-speed)]
                         (-= _G.camera.x dx)
                         (-= _G.camera.y dy)))
                     (love.keyboard.isDown (. _G.control-map :secondary))
                     (do
                       (when (love.keyboard.isDown (. _G.control-map :left))
                         (set _G.shot.spin-x (lume.clamp (- _G.shot.spin-x spin-speed) (- 1) 1)))
                       (when (love.keyboard.isDown (. _G.control-map :right))
                         (set _G.shot.spin-x (lume.clamp (+ _G.shot.spin-x spin-speed) (- 1) 1)))
                       (when (love.keyboard.isDown (. _G.control-map :up))
                         (set _G.shot.spin-y (lume.clamp (- _G.shot.spin-y spin-speed) (- 1) 1)))
                       (when (love.keyboard.isDown (. _G.control-map :down))
                         (set _G.shot.spin-y (lume.clamp (+ _G.shot.spin-y spin-speed) (- 1) 1))))
                     (do
                       (when (love.keyboard.isDown (. _G.control-map :left))
                         (+= _G.shot.angle speed)
                         (%= _G.shot.angle (* 2 math.pi)))
                       (when (love.keyboard.isDown (. _G.control-map :right))
                         (-= _G.shot.angle speed)
                         (%= _G.shot.angle (* 2 math.pi)))
                       (when (. _G.just-pressed (. _G.control-map :up))
                         (_G.shot.change-type "up"))
                       (when (. _G.just-pressed (. _G.control-map :down))
                         (_G.shot.change-type "down"))))
                 (when (love.keyboard.isDown (. _G.control-map :primary))
                   (if (= _G.shot.type "fly")
                       (set _G.shot.state "preshot-fly")
                       (set _G.shot.state "preshot-normal")))))
    "preshot-fly" (do
                    (when (. _G.just-pressed (. _G.control-map :secondary))
                      (set _G.shot.state "aiming"))
                    (when (. _G.just-pressed (. _G.control-map :primary))
                      ;; (tset _G.just-pressed (. _G.control-map :primary) nil)
                      (set _G.shot.state "charging")))
    "preshot-normal" (do
                       (when (love.keyboard.isDown (. _G.control-map :secondary))
                         (set _G.shot.state "aiming"))
                       (when (. _G.just-pressed (. _G.control-map :primary))
                         (set _G.shot.state "charging")))
    "charging" (when (. _G.just-pressed (. _G.control-map :primary))
                 (_G.shot.apply))
    "moving" (do (todo!))))

(fn _G.shot.velocity-vector [shot-type angle meter]
  (let [base-vector (if (= shot-type "fly") (_G.vector.normalize {:x 1 :y 0 :z 1}) {:x 1 :y 0 :z 0})
        base-strength (if (= shot-type "fly") _G.base-fly-strength _G.base-strength)
        velocity (-> base-vector
                     (_G.vector.rotate-by-axis-angle {:x 0 :y 0 :z 1} angle)
                     (_G.vector.scale (* meter base-strength)))]
    velocity))

(fn _G.shot.apply []
  (set _G.shot.state "moving")
  (set _G.shot.stillness-timer 0)
  (set _G.ball.velocity (_G.shot.velocity-vector _G.shot.type _G.shot.angle _G.shot.meter)))

(fn _G.shot.conclude []
  (set _G.shot.angle 0)
  (set _G.shot.spin-x 0)
  (set _G.shot.spin-y 0)
  (set _G.shot.type "roll")
  (set _G.shot.state "aiming")
  (set _G.shot.meter-timer 0)
  (set _G.shot.meter 0)
  (set _G.shot.fly-meter 0)
  (set _G.shot.stillness-timer 0))

(fn _G.shot.update [dt]
  (_G.shot.handle-controls dt)
  (case _G.shot.state
    "preshot-fly" (let [time (love.timer.getTime)
                        speed 1
                        fly-level (-> (_G.util.triangle-oscillate (% (* time speed) 1)) (* 2) (- 1))]
                    (set _G.shot.fly-meter fly-level)
                    (print fly-level))
    "charging" (do
                 (+= _G.shot.meter-timer dt)
                 (if (> _G.shot.meter-timer (* _G.shot-meter-max-time 2))
                     (do
                       (set _G.shot.meter 1)
                       (_G.shot.apply))
                     (do
                       (set _G.shot.meter (_G.util.triangle-oscillate (/ _G.shot.meter-timer (* _G.shot-meter-max-time 2))))
                       (print _G.shot.meter))))
    "moving" (do
               ;; (print "moving?")
               (_G.physics.integrate-ball _G.ball dt)
               (when (< (_G.vector.length-sq _G.ball.velocity) 0.02)
                 (+= _G.shot.stillness-timer dt)
                 (when (> _G.shot.stillness-timer 3)
                   (_G.shot.conclude))))))

(fn _G.shot.draw []
  (love.graphics.print
   (table.concat [_G.shot.state _G.shot.angle _G.shot.type _G.shot.state _G.shot.spin-x _G.shot.spin-y] "\n")
   10 10))
