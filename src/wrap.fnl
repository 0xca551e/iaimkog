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
;   (: (love.thread.newThread "require('love.event')
; while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (set _G.just-pressed {})

  (set _G.game-canvas (love.graphics.newCanvas 240 160))

  (require :src.vector)
  (require :src.geometry)
  (require :src.util)

  (require :src.config)

  (require :src.camera)
  (require :src.physics)
  (require :src.level)
  (require :src.shot)
  (require :src.ball-preview)

  (require :src.scenes.title-screen)
  (require :src.scenes.playing-course)
  (require :src.scenes.not-playing)
  (require :src.scenes.results-screen)
  
  (set _G.scene _G.title-screen-scene)
  (_G.scene.load)
  )

(fn love.draw []
  (love.graphics.setCanvas _G.game-canvas)
  (love.graphics.clear 0 0 0 0)

  (_G.scene.draw)

  (love.graphics.setCanvas)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.draw _G.game-canvas 0 0 0 _G.scale _G.scale)

  (when _G.next-scene
    (_G.scene.unload)
    (set _G.scene _G.next-scene)
    (_G.scene.load)
    (set _G.next-scene nil)))

(fn love.update [dt]
  (_G.scene.update dt)
  (lume.clear _G.just-pressed)
)

(fn love.keypressed [_key scancode _isrepeat]
  (tset _G.just-pressed scancode true))