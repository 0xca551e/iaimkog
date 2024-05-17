(require-macros :macros)
;; (require :util)

(fn love.load []
  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (love.graphics.setDefaultFilter "nearest" "nearest")
  (set _G.scale 4)
  (set _G.tile-width 28)
  (set _G.tile-height 14)
  (set _G.sprite-sheet (love.graphics.newImage "Sprite-0001.png"))
  (set _G.sprite-quads
       {:floor (love.graphics.newQuad 0 0 _G.tile-width _G.tile-height (_G.sprite-sheet:getDimensions))}))

(fn _G.to-isometric [x y z]
  (let [ix (/ (* (- x y) _G.tile-width) 2)
        iy (/ (* (- (+ x y) z) _G.tile-height) 2)]
    [ix iy]))

(fn _G.draw-floor [x y z]
  (let [[ix iy] (_G.to-isometric x y z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "floor") ix iy)))

(var lines [])
(fn love.handlers.stdin [line]
  ;; evaluate lines read from stdin as fennel code
  ;; note: for multi-line evaluating, we must not evaluate until the statement is complete.
  ;; we mark the end of a statement with a semicolon (for now, i'm too lazy to count brackets)
  (let [is-end-statement (line:match ";%s*$")
        formatted-line (line:gsub ";%s*$" "")]
    (table.insert lines formatted-line)
    (when is-end-statement
      (let [(ok val) (pcall fennel.eval (.. "(require-macros :macros)\n" (table.concat lines "\n")))]
        (print (if ok (fennel.view val) val)))
      (set lines []))))

(fn love.update [dt]
  )

(fn love.draw []
  (love.graphics.scale _G.scale)
  (_G.draw-floor 0 0 0)
  (_G.draw-floor 1 0 0)
  (_G.draw-floor 2 0 0)
  (_G.draw-floor 3 0 0)
  
  (_G.draw-floor 3 1 0)
  (_G.draw-floor 3 2 0)
  (_G.draw-floor 3 3 0)

  (_G.draw-floor 3 3 1)
  (_G.draw-floor 3 3 2)
  (_G.draw-floor 3 3 3)
  )

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  )
