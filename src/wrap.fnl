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
      (let [(ok val) (pcall fennel.eval (.. "(require-macros :macros)\n" (table.concat lines "\n")))]
        (print (if ok (fennel.view val) val)))
      (set lines []))))

(fn love.load []
  (love.window.setMode 720 480)
  (love.graphics.setDefaultFilter "nearest" "nearest")

  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (require :src.vector)
  (require :src.geometry)
  (require :src.util)

  (require :src.config)

  (require :src.camera)
  (require :src.physics)
  (require :src.level)
  (require :src.shot)
  (require :src.ball-preview)

  (set _G.just-pressed {})

  (set _G.ball-preview [])

  (set _G.paused false)

  (set _G.tris [])

  (set _G.ball {:position {:x 0 :y 0 :z 1.25}
             :radius 0.25
             :velocity {:x 0 :y 0 :z 0}
             :variant :ball})
  (set _G.drawables [_G.ball])

  (_G.level.read-file-lines "levels/test-level2.txt")
  ;; NOTE: the level is static, so we don't need to sort every frame.
  ;; in a later version this might change
  (_G.util.insertion-sort-by-mut _G.tris (fn [a b]
                                (let [[tri-a aabb-a] a
                                      [tri-b aabb-b] b]
                                  (- aabb-a.min.x aabb-b.min.x))))
  )

; (fn _G.manual-control-ball [dt]
;   (let [d (* 5 dt)
;         control _G.ball.velocity]
;     (when (love.keyboard.isDown "w") (-= control.y d))
;     (when (love.keyboard.isDown "a") (-= control.x d))
;     (when (love.keyboard.isDown "s") (+= control.y d))
;     (when (love.keyboard.isDown "d") (+= control.x d))
;     (when (love.keyboard.isDown "space") (+= control.z d))
;     (when (love.keyboard.isDown "lshift") (-= control.z d))))

(fn love.update [dt]
  (when (not _G.paused)
    ;; (_G.integrate-ball dt)
    ;; (_G.manual-control-ball dt)
    (_G.shot.update dt)))

(fn love.draw []
  (love.graphics.scale _G.scale)
  (love.graphics.draw _G.bg1)
  (when (= _G.shot.state "moving")
    (_G.camera.to-ball))
  (love.graphics.translate _G.camera.x _G.camera.y)
  (love.graphics.print (inspect _G.just-pressed))

  (_G.level.draw)

  (when (and (= _G.shot.state "aiming") (>= (# _G.ball-preview) 2))
    (_G.generate-ball-preview)
    (love.graphics.line (unpack _G.ball-preview)))

  (love.graphics.origin)
  (_G.shot.draw (love.timer.getDelta))
  
  (lume.clear _G.just-pressed))

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  (tset _G.just-pressed scancode true)
  ;; (when (= scancode "tab")
  ;;   (set _G.paused (not _G.paused)))
  ;; (when _G.paused
  ;;   (_G.integrate-ball (love.timer.getDelta)))
  )
