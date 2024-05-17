(require-macros :macros)
;; (require :util)

(fn love.load []
  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start))

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

(set _G.font (love.graphics.newFont 32))
(set _G.r 0)
(set _G.color [1 1 1 1])
(set _G.spinniness 1)

(fn love.update [dt]
  (+= _G.r (* dt _G.spinniness)))

(fn love.draw []
  (let [width (love.graphics.getWidth)
        x (/ width 2)
        y (/ (love.graphics.getHeight) 2)]
    (love.graphics.origin)
    (love.graphics.translate x y)
    (love.graphics.rotate _G.r)
    ;; (love.graphics.circle "fill" 0 0 5)
    (love.graphics.setColor (unpack _G.color))
    (love.graphics.setFont _G.font)
    (love.graphics.printf "it's lispin time"
                          (- x) 0 width "center")))

(fn love.keypressed [_key scancode _isrepeat]
  ;; (print scancode)
  )
