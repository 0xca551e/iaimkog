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
  (set _G.par (. _G.course-hole-pars n))

  (set _G.tris [])
  (set _G.height-map [])
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

  ; (_G.generate-ball-preview)
  ; (_G.camera.to-preview-tail)
  (set _G.should-generate-ball-preview true))

(fn _G.playing-course-scene.unload []
  ; TODO: course data should hold what song to play
  (love.audio.stop _G.course-1-music)
  (love.audio.stop _G.course-2-music))

(fn _G.playing-course-scene.load []
  (set _G.ball-preview-dt-acc 0)
  (set _G.ball-preview [])
  (set _G.ball-shadow-preview [])
  (set _G.last-generate-ball-request 0)

  (if _G.is-level-2
    (love.audio.play _G.course-2-music)
    (love.audio.play _G.course-1-music))

  (set _G.course-scores [])
  (if _G.is-level-2
    (do
      (set _G.course-holes [
        "levels/up-two-stairs.txt" ;
        "levels/halfpipe-with-hole.txt"
        "levels/spiral-down.txt" ; move to early trickshot city
        "levels/fly-shot-example.txt"
        "levels/jump-double-rebound.txt" ; move to trickshot city as an early level, par 4?
        "levels/donut-hard.txt"
        "levels/neo.txt" ; move to trickshot city, early-mid
        "levels/neo-tower.txt"
        ])
      (set _G.course-hole-pars [3 3 3 3 3 3 3 3]))
    (do 
      (set _G.course-holes [
        "levels/1-1.txt" ; super duper easy, par 3
        "levels/line-it-up.txt" ; should be very early level near 1-1. also, move the hole 1 unit closer to make it HIO viable
        "levels/updown-level.txt" ; easy ho1, par 3
        "levels/basic-rebound.txt" ; keep, put in the middle
        "levels/u-shaped.txt" ; par 3
        "levels/carved-hill.txt" ; good, after behind the wall
        "levels/behind-the-wall.txt" ; the later but
        "levels/easy-islands.txt" ; TODO: make this level
        "levels/pachinko.txt" ; last level
        ])
      (set _G.course-hole-pars [3 3 3 3 3 3 3 3 3])))

  (set _G.dt-acc 0)
  (set _G.timestep (/ 1 60))
  (set _G.max-steps-per-frame 5)
  (set _G.paused false)
  
  (_G.playing-course-scene.set-hole 1))

(fn _G.manual-control-ball [dt]
  (let [d (* 5 dt)
        control _G.ball.velocity]
    (when (love.keyboard.isDown "w") (-= control.x d) (-= control.y d))
    (when (love.keyboard.isDown "a") (-= control.x d) (+= control.y d))
    (when (love.keyboard.isDown "s") (+= control.x d) (+= control.y d))
    (when (love.keyboard.isDown "d") (+= control.x d) (-= control.y d))
    (when (love.keyboard.isDown "space") (+= control.z d))
    (when (love.keyboard.isDown "lshift") (-= control.z d))))

(fn _G.playing-course-scene.update [dt]
  (+= _G.dt-acc dt)
  (+= _G.ball-preview-dt-acc dt)
  (when (>= _G.ball-preview-dt-acc (/ 1 20))
    (%= _G.ball-preview-dt-acc (/ 1 20))
    (if _G.should-generate-ball-preview
      (do
        (set _G.last-generate-ball-request 0)
        ; (_G.generate-ball-preview 0.25)
        ; (_G.camera.to-preview-tail)
        (set _G.requested-fast-preview true)
        (set _G.should-generate-ball-preview false))
      (do
        (+= _G.last-generate-ball-request 1)
        (when (= _G.last-generate-ball-request 10)
          ; (print "ENHANCE")
          ; (_G.generate-ball-preview 1.0)
          ; (_G.camera.to-preview-tail)
          (set _G.requested-full-preview true)))))
  (var steps-left _G.max-steps-per-frame)
  (while (and (> _G.dt-acc _G.timestep) (not= steps-left 0))
    (coroutine.resume _G.generate-ball-preview1)
    (coroutine.resume _G.generate-ball-preview2)
    (-= _G.dt-acc dt)
    (-= steps-left 1)
    (when (not _G.paused)
      ;; (_G.integrate-ball dt)
      (_G.manual-control-ball _G.timestep)
      (_G.shot.update _G.timestep))
    (when _G.ball.just-collided-sound
      (local bounce-sound (_G.bounce-sound:clone))
      (local volume (-> _G.ball.velocity.z (/ 3) (math.min 1)))
      (when (> volume 0.25)
        (_G.bounce-sound:setVolume volume)
        (love.audio.play bounce-sound)))
      (set _G.ball.just-collided-sound false)))

(fn _G.playing-course-scene.draw []
  (if _G.is-level-2
    (love.graphics.draw _G.bg2)
    (love.graphics.draw _G.bg1))
  

  (love.graphics.translate _G.camera.x _G.camera.y)
  (_G.level.draw)
  (love.graphics.setShader)

  (love.graphics.setColor 1 1 1 1)
  (when (and (not= _G.shot.state "moving")
             (not= _G.shot.state "success")
             (>= (# _G.ball-preview) 2))
    (let [offset (-> (love.timer.getTime)
                     (* 20)
                     (% 10)
                     (math.floor)
                     (* 2))
          dashed-lines (_G.util.segments _G.ball-preview 10 10 offset)
          dashed-shadow-lines (_G.util.segments _G.ball-shadow-preview 10 10 offset)]
      (love.graphics.setColor 0 0 0 1)
      (each [_ v (ipairs dashed-shadow-lines)]
        (when (>= (# v) 4)
          (love.graphics.line (unpack v))))
      (love.graphics.setColor 1 1 1 1)
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
