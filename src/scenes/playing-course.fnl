(require-macros :src.macros)

(set _G.playing-course-scene {})

(fn _G.playing-course-scene.next-hole []
  (table.insert _G.course-scores _G.shot-no)
  (if (= _G.current-hole (# _G.course-holes))
      (set _G.next-scene _G.result-screen-scene)
      (_G.playing-course-scene.set-hole (+ _G.current-hole 1))))

(fn _G.playing-course-scene.set-hole [n]
  (set _G.current-hole n)
  (set _G.shot-no 0)
  (set _G.par 3)

  (set _G.tris [])
  (set _G.level-hole _G.vector.zero)
  (set _G.ball {:position _G.vector.zero
                :radius 0.25
                :velocity _G.vector.zero
                :variant :ball
                :animation {:timer 0
                            :frame-duration (/ 1 6)}
                :draw-offset {:x 8 :y 6 :z -0.75}
                :collided false
                :just-collided false
                :spin-x 0
                :spin-y 0})
  (tset _G.ball :last-settled-at _G.ball.position)
  (set _G.drawables [_G.ball])

  (_G.level.read-file-lines (. _G.course-holes _G.current-hole))
  ;; NOTE: the level is static, so we don't need to sort every frame.
  ;; in a later version this might change
  (_G.util.insertion-sort-by-mut _G.tris (fn [a b]
                                (let [[tri-a aabb-a] a
                                      [tri-b aabb-b] b]
                                  (- aabb-a.min.x aabb-b.min.x))))

  (set _G.shot.state "moving")

  (_G.generate-ball-preview)
  (_G.camera.to-preview-tail))

(fn _G.playing-course-scene.unload [])

(fn _G.playing-course-scene.load []
  (set _G.course-scores [])
  (set _G.course-holes ["levels/1-1.txt" "levels/updown-level.txt"])
  (set _G.course-hole-pars [3 3])

  (set _G.dt-acc 0)
  (set _G.timestep (/ 1 60))
  (set _G.max-steps-per-frame 5)
  (set _G.paused false)
  
  (_G.playing-course-scene.set-hole 1))

; (fn _G.manual-control-ball [dt]
;   (let [d (* 5 dt)
;         control _G.ball.velocity]
;     (when (love.keyboard.isDown "w") (-= control.x d) (-= control.y d))
;     (when (love.keyboard.isDown "a") (-= control.x d) (+= control.y d))
;     (when (love.keyboard.isDown "s") (+= control.x d) (+= control.y d))
;     (when (love.keyboard.isDown "d") (+= control.x d) (-= control.y d))
;     (when (love.keyboard.isDown "space") (+= control.z d))
;     (when (love.keyboard.isDown "lshift") (-= control.z d))))

(fn _G.playing-course-scene.update [dt]
  (+= _G.dt-acc dt)
  (var steps-left _G.max-steps-per-frame)
  (while (and (> _G.dt-acc _G.timestep) (not= steps-left 0))
    (-= _G.dt-acc dt)
    (-= steps-left 1)
    (when (not _G.paused)
      ;; (_G.integrate-ball dt)
      ; (_G.manual-control-ball _G.timestep)
      (_G.shot.update _G.timestep))
    ; (when _G.ball.just-collided
    ;   (local bounce-sound (_G.bounce-sound:clone))
    ;   (local volume (-> _G.ball.velocity.z (/ 2) (math.min 1)))
    ;   (bounce-sound:setVolume volume)
    ;   (love.audio.play bounce-sound))
    ; (set _G.ball.just-collided false)
    ))

(fn _G.playing-course-scene.draw []
  (love.graphics.draw _G.bg1)

  (love.graphics.translate _G.camera.x _G.camera.y)

  (_G.level.draw)

  (love.graphics.setColor 1 1 1 1)
  (when (and (not= _G.shot.state "moving")
             (not= _G.shot.state "success")
             (>= (# _G.ball-preview) 2))
    (let [offset (-> (love.timer.getTime)
                     (* 20)
                     (% 10)
                     (math.floor)
                     (* 2))
          dashed-lines (_G.util.segments _G.ball-preview 10 10 offset)]
      (each [_ v (ipairs dashed-lines)]
        (when (>= (# v) 4)
          (love.graphics.line (unpack v))))))

  (if (not= _G.shot.state "aiming")
    (_G.camera.to-ball))
  (_G.camera.lerp-to-target (love.timer.getDelta))

  (love.graphics.origin)
  (_G.shot.draw (love.timer.getDelta))
  (love.graphics.print (.. "Shot #" _G.shot-no))
  (let [text (.. "Par " _G.par)
        w (_G.font:getWidth text)
        x (- 240 w)
        y 0]
    (love.graphics.print text x y)))