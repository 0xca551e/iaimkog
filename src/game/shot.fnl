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
    (set _G.shot.spin-y 0))
  
  (_G.generate-ball-preview)
  (_G.camera.to-preview-tail)

  )

(fn _G.shot.handle-controls [dt]
  (case _G.shot.state
    "aiming" (do
               (let [shift-factor (if (love.keyboard.isDown (. _G.control-map :fine-tune)) 0.5 1)
                     speed (* shift-factor _G.rotation-speed dt)
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

                         (_G.camera.set-target (- _G.camera.target.to.x dx) (- _G.camera.target.to.y dy) 0 _G.linear)
                         
                         ))
                     (love.keyboard.isDown (. _G.control-map :secondary))
                     (do
                       (when (love.keyboard.isDown (. _G.control-map :left))
                         (set _G.shot.spin-x (lume.clamp (- _G.shot.spin-x spin-speed) (- 1) 1))

                         (_G.generate-ball-preview)
                         (_G.camera.to-preview-tail)
                         
                         )
                       (when (love.keyboard.isDown (. _G.control-map :right))
                         (set _G.shot.spin-x (lume.clamp (+ _G.shot.spin-x spin-speed) (- 1) 1))
                         
                         (_G.generate-ball-preview)
                         (_G.camera.to-preview-tail)
                         
                         )
                       (when (and (= _G.shot.type "fly") (love.keyboard.isDown (. _G.control-map :down)))
                         (set _G.shot.spin-y (lume.clamp (- _G.shot.spin-y spin-speed) (- 1) 1))
                         
                         (_G.generate-ball-preview)
                         (_G.camera.to-preview-tail)

                         )
                       (when (and (= _G.shot.type "fly") (love.keyboard.isDown (. _G.control-map :up)))
                         (set _G.shot.spin-y (lume.clamp (+ _G.shot.spin-y spin-speed) (- 1) 1))
                         
                         (_G.generate-ball-preview)
                         (_G.camera.to-preview-tail)

                         ))
                     (do
                       (when (love.keyboard.isDown (. _G.control-map :left))
                         (+= _G.shot.angle speed)
                         (%= _G.shot.angle (* 2 math.pi))

                         (_G.generate-ball-preview)
                         (_G.camera.to-preview-tail)
                         
                         )
                       (when (love.keyboard.isDown (. _G.control-map :right))
                         (-= _G.shot.angle speed)
                         (%= _G.shot.angle (* 2 math.pi))

                         (_G.generate-ball-preview)
                         (_G.camera.to-preview-tail)

                         )
                       (when (. _G.just-pressed (. _G.control-map :up))
                         (_G.shot.change-type "up"))
                       (when (. _G.just-pressed (. _G.control-map :down))
                         (_G.shot.change-type "down"))))
                 (when (love.keyboard.isDown (. _G.control-map :primary))
                   (if (= _G.shot.type "fly")
                       (do
                         (set _G.shot.state "preshot-fly")
                         (love.audio.play _G.fly-meter-sound))
                       (set _G.shot.state "preshot-normal")))))
    "preshot-fly" (do
                    (when (. _G.just-pressed (. _G.control-map :secondary))
                      (love.audio.stop _G.fly-meter-sound)
                      (set _G.shot.state "aiming"))
                    (when (. _G.just-pressed (. _G.control-map :primary))
                      ;; (tset _G.just-pressed (. _G.control-map :primary) nil)
                      (_G.meter-sound:setPitch _G.meter-sound-low-pitch)
                      (set _G.shot.state "charging")
                      (love.audio.stop _G.fly-meter-sound)
                      (love.audio.play _G.meter-sound)))
    "preshot-normal" (do
                       (when (love.keyboard.isDown (. _G.control-map :secondary))
                         (set _G.shot.state "aiming"))
                       (when (. _G.just-pressed (. _G.control-map :primary))
                         (set _G.shot.state "charging")
                         (_G.meter-sound:setPitch _G.meter-sound-low-pitch)
                         (love.audio.stop _G.fly-meter-sound)
                         (love.audio.play _G.meter-sound)))
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
  (set _G.ball.velocity (_G.shot.velocity-vector _G.shot.type _G.shot.angle _G.shot.meter))
  (set _G.ball.spin-x _G.shot.spin-x)
  (set _G.ball.spin-y _G.shot.fly-meter)
  (love.audio.stop _G.meter-sound))

(fn _G.shot.conclude [success]
  (set _G.ball.collided false)
  (set _G.ball.just-collided false)
  (set _G.ball.velocity _G.vector.zero)

  (set _G.shot.angle 0)
  (set _G.shot.spin-x 0)
  (set _G.shot.spin-y 0)
  (set _G.shot.type "roll")
  (set _G.shot.state "aiming")
  (set _G.shot.meter-timer 0)
  (set _G.shot.meter 0)
  (set _G.shot.fly-meter 0)
  (set _G.shot.stillness-timer 0)
  (if success
      (do
        (set _G.ball.last-settled-at _G.ball.position)
        (let [hole-bottom (_G.vector.add _G.level-hole {:x 0.5 :y 0.5 :z -1})
              ball-bottom (_G.vector.subtract _G.ball.position {:x 0 :y 0 :z _G.ball.radius})
              distance-to-hole (_G.vector.length (_G.vector.subtract ball-bottom hole-bottom))]
          (if (< distance-to-hole 1.2)
            (do
              (set _G.shot-success-timer 8)
              (set _G.shot.state "success"))
            (+= _G.shot-no 1))))
      (set _G.ball.position _G.ball.last-settled-at))
  (_G.generate-ball-preview)
  (_G.camera.to-preview-tail))

(fn _G.shot.update [dt]
  (_G.shot.handle-controls dt)
  (case _G.shot.state
    "preshot-fly" (let [time (love.timer.getTime)
                        fly-level (-> (_G.util.triangle-oscillate (% (/ time _G.fly-meter-cycle-time) 1)) (* 2) (- 1))]
                    (set _G.shot.fly-meter fly-level)

                    (_G.fly-meter-sound:setPitch (lume.lerp _G.fly-meter-sound-low-pitch _G.fly-meter-sound-high-pitch (-> _G.shot.fly-meter (+ 1) (/ 2)))))
    "charging" (do
                 (+= _G.shot.meter-timer dt)
                 (if (> _G.shot.meter-timer (* _G.shot-meter-max-time 2))
                     (do
                       (set _G.shot.meter 0.05)
                       (_G.shot.apply))
                     (do
                       (set _G.shot.meter (_G.util.triangle-oscillate (/ _G.shot.meter-timer (* _G.shot-meter-max-time 2))))))
                 
                 (_G.meter-sound:setPitch (lume.lerp _G.meter-sound-low-pitch _G.meter-sound-high-pitch _G.shot.meter)))
    "moving" (do
               ;; (print "moving?")
               (_G.physics.integrate-ball _G.ball dt)
               (when (< (_G.vector.length-sq _G.ball.velocity) 0.02)
                 (+= _G.shot.stillness-timer dt)
                 (when (> _G.shot.stillness-timer 3)
                   (_G.shot.conclude true)))
               (when (< _G.ball.position.z -1)
                 (_G.shot.conclude false)))
    "success" (do
      (-= _G.shot-success-timer dt)
      (when (<= _G.shot-success-timer 0)
        (_G.playing-course-scene.next-hole)))))

(fn _G.shot.draw []
  ; (love.graphics.print
  ;  (table.concat [_G.shot.state _G.shot.angle _G.shot.type _G.shot.state _G.shot.spin-x _G.shot.spin-y] "\n")
  ;  10 10)
  (when (= _G.shot.state "success")
    (let [text (_G.util.score-name _G.shot-no _G.par)
          w (_G.font:getWidth text)
          x (/ (- 240 w) 2)
          y 60]
      (love.graphics.print text x y)))
  (when (or (= _G.shot.state "preshot-fly")
            (= _G.shot.state "preshot-normal")
            (= _G.shot.state "charging")
            (and (= _G.shot.state "aiming") (love.keyboard.isDown (. _G.control-map :secondary))))
    (let [overlay-color [0 0 0 0.5]
          overlay-x 0
          overlay-y 0
          overlay-width 50
          overlay-height 50
          ball-stroke-color [0 0 0 1]
          ball-line-width 5
          ball-fill-color [1 0 0 1]
          ball-center-x (+ overlay-x (/ overlay-width 2))
          ball-center-y (+ overlay-y (/ overlay-height 2))
          ball-radius 15
          spin-line-color [1 1 1 1]
          spin-line-width 1
          topspin-line-x1 (/ (- overlay-width ball-radius ball-radius 10) 2)
          topspin-line-x2 (+ topspin-line-x1 ball-radius ball-radius 10)
          topspin-line-y (- ball-center-y (* _G.shot.spin-y ball-radius))
          fly-meter-color [0 0 1 1]
          fly-meter-line-width 3
          topspin-timer-line-x1 (- (+ overlay-x (/ overlay-width 2)) 3)
          topspin-timer-line-x2 (+ (+ overlay-x (/ overlay-width 2)) 3)
          topspin-timer-line-y (- ball-center-y (* _G.shot.fly-meter ball-radius))
          sidespin-line-y1 (/ (- overlay-height ball-radius ball-radius 10) 2)
          sidespin-line-y2 (+ sidespin-line-y1 ball-radius ball-radius 10)
          sidespin-line-x (+ ball-center-x (* _G.shot.spin-x ball-radius))
          meter-bar-empty-color [0 0 0 1]
          meter-bar-y-padding 5
          meter-bar-x (+ overlay-x overlay-width 4)
          meter-bar-y (+ overlay-y meter-bar-y-padding)
          meter-bar-width 5
          meter-bar-height (- (+ overlay-y overlay-height) meter-bar-y-padding meter-bar-y-padding)
          meter-bar-filled-color [1 1 0 1]
          meter-bar-filled-height (math.floor (* meter-bar-height _G.shot.meter))
          meter-bar-filled-y (+ meter-bar-y (- meter-bar-height meter-bar-filled-height))]
      (love.graphics.setColor (unpack overlay-color))
      (love.graphics.rectangle "fill" overlay-x overlay-y overlay-width overlay-height)
      (love.graphics.setColor (unpack ball-fill-color))
      (love.graphics.circle "fill" ball-center-x ball-center-y ball-radius)
      (love.graphics.setColor (unpack ball-stroke-color))
      (love.graphics.setLineWidth ball-line-width)
      (love.graphics.circle "line" ball-center-x ball-center-y ball-radius)
      (love.graphics.setColor (unpack spin-line-color))
      (love.graphics.setLineWidth spin-line-width)
      (love.graphics.line topspin-line-x1 topspin-line-y topspin-line-x2 topspin-line-y)
      (love.graphics.line sidespin-line-x sidespin-line-y1 sidespin-line-x sidespin-line-y2)
      (love.graphics.setColor fly-meter-color)
      (love.graphics.setLineWidth fly-meter-line-width)
      (love.graphics.line topspin-timer-line-x1 topspin-timer-line-y topspin-timer-line-x2 topspin-timer-line-y)
      (love.graphics.setColor (unpack meter-bar-empty-color))
      (love.graphics.rectangle "fill" meter-bar-x meter-bar-y meter-bar-width meter-bar-height)
      (love.graphics.setColor (unpack meter-bar-filled-color))
      (love.graphics.rectangle "fill" meter-bar-x meter-bar-filled-y meter-bar-width meter-bar-filled-height)
      (love.graphics.setColor 1 1 1 1)
      (love.graphics.setLineWidth 1))))
