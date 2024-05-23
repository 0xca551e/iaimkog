(require-macros :src.macros)

(var lines [])
(fn love.handlers.stdin [line]
  ;; evaluate lines read from stdin as fennel code
  ;; note: for multi-line evaluating, we must not evaluate until the statement is complete.
  ;; we mark the end of a statement with a semicolon (for now, i'm too lazy to count brackets)
  (let [is-end-statement (line:match ";END%s*$")
        formatted-line (line:gsub ";END%s*$" "")]
    (table.insert lines formatted-line)
    (when is-end-statement
      (let [(ok val) (pcall fennel.eval (.. "(require-macros :src.macros)\n" (table.concat lines "\n")))]
        (print (if ok (fennel.view val) val)))
      (set lines []))))

(fn love.load []
  (love.window.setMode 720 480)
  (love.graphics.setDefaultFilter "nearest" "nearest")
  (love.graphics.setLineStyle "rough")

  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (require :src.vector)
  (require :src.geometry)
  (require :src.util)

  (require :src.config)

  (require :src.game.camera)
  (require :src.game.physics)
  (require :src.game.level)
  (require :src.game.shot)
  (require :src.game.ball-preview)

  (set _G.dt-acc 0)
  (set _G.timestep (/ 1 60))
  (set _G.max-steps-per-frame 5)

  (set _G.just-pressed {})

  (set _G.ball-preview-canvas (love.graphics.newCanvas 240 160))
  (set _G.ball-preview [])

  (set _G.paused false)

  (set _G.tris [])

  (set _G.level-hole _G.vector.zero)

  (set _G.ball {:position {:x -6 :y 5 :z 1.25}
             :radius 0.25
             :velocity {:x 0 :y 0 :z 0}
             :variant :ball
             :animation {:timer 0
                         :frame-duration (/ 1 6)}
             :draw-offset {:x 8 :y 6 :z -0.75}
             :collided false
             :just-collided false
             :spin-x 0})
  (tset _G.ball :last-settled-at _G.ball.position)
  (set _G.drawables [_G.ball])

  (_G.level.read-file-lines "levels/updown-level.txt")
  ;; NOTE: the level is static, so we don't need to sort every frame.
  ;; in a later version this might change
  (_G.util.insertion-sort-by-mut _G.tris (fn [a b]
                                (let [[tri-a aabb-a] a
                                      [tri-b aabb-b] b]
                                  (- aabb-a.min.x aabb-b.min.x))))
  )

(fn _G.manual-control-ball [dt]
  (let [d (* 5 dt)
        control _G.ball.velocity]
    (when (love.keyboard.isDown "w") (-= control.x d) (-= control.y d))
    (when (love.keyboard.isDown "a") (-= control.x d) (+= control.y d))
    (when (love.keyboard.isDown "s") (+= control.x d) (+= control.y d))
    (when (love.keyboard.isDown "d") (+= control.x d) (-= control.y d))
    (when (love.keyboard.isDown "space") (+= control.z d))
    (when (love.keyboard.isDown "lshift") (-= control.z d))))

(fn love.update [dt]
  (+= _G.dt-acc dt)
  (var steps-left _G.max-steps-per-frame)
  (while (and (> _G.dt-acc _G.timestep) (not= steps-left 0))
    (-= _G.dt-acc dt)
    (-= steps-left 1)
    (when (not _G.paused)
      ;; (_G.integrate-ball dt)
      (_G.manual-control-ball _G.timestep)
      (_G.shot.update _G.timestep))
    (when _G.ball.just-collided
      (local bounce-sound (_G.bounce-sound:clone))
      (local volume (-> _G.ball.velocity.z (/ 2) (math.min 1)))
      (bounce-sound:setVolume volume)
      (love.audio.play bounce-sound))
    (set _G.ball.just-collided false)
    (lume.clear _G.just-pressed)))

(fn love.draw []
  (love.graphics.setCanvas _G.ball-preview-canvas)

  (love.graphics.clear 0 0 0 0)
  (love.graphics.draw _G.bg1)

  (love.graphics.translate _G.camera.x _G.camera.y)

  (_G.level.draw)

  (love.graphics.setColor 1 1 1 1)
  (when (and (= _G.shot.state "aiming") (>= (# _G.ball-preview) 2))
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

  (love.graphics.setCanvas)
  (love.graphics.origin)

  (love.graphics.draw _G.ball-preview-canvas 0 0 0 _G.scale _G.scale)

  (_G.shot.draw (love.timer.getDelta)))

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  (tset _G.just-pressed scancode true)
  ;; (when (= scancode "tab")
  ;;   (set _G.paused (not _G.paused)))
  ;; (when _G.paused
  ;;   (_G.integrate-ball (love.timer.getDelta)))
  )
