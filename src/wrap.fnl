; (require-macros :src.macros)

; (var lines [])
; (fn love.handlers.stdin [line]
;   ;; evaluate lines read from stdin as fennel code
;   ;; note: for multi-line evaluating, we must not evaluate until the statement is complete.
;   ;; we mark the end of a statement with a semicolon (for now, i'm too lazy to count brackets)
;   (let [is-end-statement (line:match ";END%s*$")
;         formatted-line (line:gsub ";END%s*$" "")]
;     (table.insert lines formatted-line)
;     (when is-end-statement
;       (let [(ok val) (pcall fennel.eval (.. "(require-macros :src.macros)\n" (table.concat lines "\n")))]
;         (print (if ok (fennel.view val) val)))
;       (set lines []))))

; (fn love.load []
;   (love.window.setMode 720 480)
;   (love.graphics.setDefaultFilter "nearest" "nearest")
;   (love.graphics.setLineStyle "rough")

;   ;; start a thread listening on stdin
;   (: (love.thread.newThread "require('love.event')
; while 1 do love.event.push('stdin', io.read('*line')) end") :start)

;   (require :src.vector)
;   (require :src.geometry)
;   (require :src.util)

;   (require :src.config)

;   (require :src.game.camera)
;   (require :src.game.physics)
;   (require :src.game.level)
;   (require :src.game.shot)
;   (require :src.game.ball-preview)

;   (set _G.dt-acc 0)
;   (set _G.timestep (/ 1 60))
;   (set _G.max-steps-per-frame 5)

;   (set _G.just-pressed {})

;   (set _G.ball-preview-canvas (love.graphics.newCanvas 240 160))
;   (set _G.ball-preview [])

;   (set _G.paused false)

;   (set _G.tris [])

;   (set _G.level-hole _G.vector.zero)

;   (set _G.ball {:position _G.vector.zero
;                 :radius 0.25
;                 :velocity _G.vector.zero
;                 :variant :ball
;                 :animation {:timer 0
;                             :frame-duration (/ 1 6)}
;                 :draw-offset {:x 8 :y 6 :z -0.75}
;                 :collided false
;                 :just-collided false
;                 :spin-x 0
;                 :spin-y 0})
;   (tset _G.ball :last-settled-at _G.ball.position)
;   (set _G.drawables [_G.ball])

;   (_G.level.read-file-lines "levels/1-1.txt")
;   ;; NOTE: the level is static, so we don't need to sort every frame.
;   ;; in a later version this might change
;   (_G.util.insertion-sort-by-mut _G.tris (fn [a b]
;                                 (let [[tri-a aabb-a] a
;                                       [tri-b aabb-b] b]
;                                   (- aabb-a.min.x aabb-b.min.x))))
;   )

; (fn _G.manual-control-ball [dt]
;   (let [d (* 5 dt)
;         control _G.ball.velocity]
;     (when (love.keyboard.isDown "w") (-= control.x d) (-= control.y d))
;     (when (love.keyboard.isDown "a") (-= control.x d) (+= control.y d))
;     (when (love.keyboard.isDown "s") (+= control.x d) (+= control.y d))
;     (when (love.keyboard.isDown "d") (+= control.x d) (-= control.y d))
;     (when (love.keyboard.isDown "space") (+= control.z d))
;     (when (love.keyboard.isDown "lshift") (-= control.z d))))

; (fn love.update [dt]
;   (+= _G.dt-acc dt)
;   (var steps-left _G.max-steps-per-frame)
;   (while (and (> _G.dt-acc _G.timestep) (not= steps-left 0))
;     (-= _G.dt-acc dt)
;     (-= steps-left 1)
;     (when (not _G.paused)
;       ;; (_G.integrate-ball dt)
;       (_G.manual-control-ball _G.timestep)
;       (_G.shot.update _G.timestep))
;     ; (when _G.ball.just-collided
;     ;   (local bounce-sound (_G.bounce-sound:clone))
;     ;   (local volume (-> _G.ball.velocity.z (/ 2) (math.min 1)))
;     ;   (bounce-sound:setVolume volume)
;     ;   (love.audio.play bounce-sound))
;     ; (set _G.ball.just-collided false)
;     (lume.clear _G.just-pressed)))

; (fn love.draw []
;   (love.graphics.setCanvas _G.ball-preview-canvas)

;   (love.graphics.clear 0 0 0 0)
;   (love.graphics.draw _G.bg1)

;   (love.graphics.translate _G.camera.x _G.camera.y)

;   (_G.level.draw)

;   (love.graphics.setColor 1 1 1 1)
;   (when (and (or (= _G.shot.state "aiming")
;                  (= _G.shot.state "preshot-roll")
;                  (= _G.shot.state "preshot-fly"))
;              (>= (# _G.ball-preview) 2))
;     (let [offset (-> (love.timer.getTime)
;                      (* 20)
;                      (% 10)
;                      (math.floor)
;                      (* 2))
;           dashed-lines (_G.util.segments _G.ball-preview 10 10 offset)]
;       (each [_ v (ipairs dashed-lines)]
;         (when (>= (# v) 4)
;           (love.graphics.line (unpack v))))))

;   (if (not= _G.shot.state "aiming")
;     (_G.camera.to-ball))
;   (_G.camera.lerp-to-target (love.timer.getDelta))

;   (love.graphics.origin)
;   (_G.shot.draw (love.timer.getDelta))

;   (love.graphics.setCanvas)

;   (love.graphics.draw _G.ball-preview-canvas 0 0 0 _G.scale _G.scale))

; (fn love.keypressed [_key scancode _isrepeat]
;   ;; (print scancode)
;   (tset _G.just-pressed scancode true)
;   ;; (when (= scancode "tab")
;   ;;   (set _G.paused (not _G.paused)))
;   ;; (when _G.paused
;   ;;   (_G.integrate-ball (love.timer.getDelta)))
;   )



(fn love.load []
  (set _G.font
  (love.graphics.newImageFont "sprites/sprFont_0.png"
    (.. " !\"#$%&'("
    ")*+,-./0"
    "12345678"
    "9:;<=>?@"
    "ABCDEFGH"
    "IJKLMNOP"
    "QRSTUVWX"
    "YZ[\\]^_`"
    "abcdefgh"
    "ijklmnop"
    "qrstuvwx"
    "yz{|}~"))
)
(love.graphics.setFont _G.font)

  (love.window.setMode 720 480)
  (love.graphics.setDefaultFilter "nearest" "nearest")
  (love.graphics.setLineStyle "rough")

  ;; start a thread listening on stdin
  (: (love.thread.newThread "require('love.event')
while 1 do love.event.push('stdin', io.read('*line')) end") :start)

  (set _G.just-pressed {})

  (set _G.game-canvas (love.graphics.newCanvas 240 160))

  (require :src.vector)
  (require :src.geometry)
  (require :src.util)

  (require :src.config)

  (require :src.game.camera)
  (require :src.game.physics)
  (require :src.game.level)
  (require :src.game.shot)
  (require :src.game.ball-preview)
  
  (set _G.state
  { :menu-open false
    :menu-items [{:text "Play game"
                  :on-select (fn []
                                (set _G.state.selecting-course true))}
                                {:text "Don't play game"
                                 :on-select (fn [] (print "TODO don't play game"))}]
    :menu-items-selected 1
    :selecting-course false
    :course-select-items [{:id "world-1"
                           :name "Intro Woodlands"
                           :image _G.bg1
                           :locked false}
                          {:id "world-2"
                           :name "Trickshot City"
                           :image _G.bg2
                           :locked true}]
    :course-selected 1
  }))

(fn love.draw []
  (love.graphics.setCanvas _G.game-canvas)
  (love.graphics.clear 0 0 0 0)

  (love.graphics.draw _G.bg1)
  (love.graphics.draw _G.title-screen-logo)

  (if _G.state.selecting-course
    (do
      (love.graphics.setColor 0 0 0 0.6)
      (love.graphics.rectangle "fill" 0 0 240 160)
      (love.graphics.setColor 1 1 1 1)

      (let [text "Select course"
            text-width (_G.font:getWidth text)
            text-x (math.floor (/ (- 240 text-width) 2))]
        (love.graphics.print text text-x 20))

      (let [text (. _G.state.course-select-items _G.state.course-selected :name)
            text-width (_G.font:getWidth text)
            text-x (math.floor (/ (- 240 text-width) 2))]
        (love.graphics.print text text-x 110))

      (each [i v (ipairs _G.state.course-select-items)]
        (let [course-window-width 60
              course-window-height 40
              course-window-x (* (+ i (- 1 _G.state.course-selected)) (/ (- 240 course-window-width) 2))
              course-window-y (/ (- 160 course-window-height) 2)]
          (when (= i _G.state.course-selected)
            (love.graphics.rectangle "fill" (- course-window-x 2) (- course-window-y 2) (+ course-window-width 4) (+ course-window-height 4)))
          (love.graphics.draw (. _G.state.course-select-items i :image) course-window-x course-window-y 0 (/ course-window-width 240) (/ course-window-height 160)))))
    _G.state.menu-open
    (do
      (love.graphics.setColor 0 0 0 0.6)
      (love.graphics.rectangle "fill" 0 0 240 160)
      (love.graphics.setColor 1 1 1 1)
      (each [i v (ipairs _G.state.menu-items)]
        (let [menu-offset-x 60
              menu-offset-y 60
              menu-item-offset-y (* (- i 1) 16)
              menu-item-y (+ menu-offset-y menu-item-offset-y)]
          (when (= i _G.state.menu-items-selected)
            (love.graphics.setColor (unpack (. _G.color-map :viking)))
            (love.graphics.rectangle "fill" menu-offset-x menu-item-y (_G.font:getWidth (. _G.state.menu-items _G.state.menu-items-selected :text)) 16)
            (love.graphics.setColor (unpack (. _G.color-map :white)))
            (love.graphics.rectangle "line" menu-offset-x menu-item-y (_G.font:getWidth (. _G.state.menu-items _G.state.menu-items-selected :text)) 16))
          (love.graphics.setColor 1 1 1 1)
          (love.graphics.print v.text menu-offset-x menu-item-y))))
    ; else
    (do
      (let [text "Press [x] to start!"
            text-width (_G.font:getWidth text)
            text-x (math.floor (/ (- 240 text-width) 2))]
        (love.graphics.print text text-x 140))))

  (love.graphics.setCanvas)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.draw _G.game-canvas 0 0 0 _G.scale _G.scale))

(fn love.update []
  (if _G.state.selecting-course
    (do
      (when (. _G.just-pressed _G.control-map.primary)
        (print "TODO load level"))
      (when (. _G.just-pressed _G.control-map.secondary)
        (set _G.state.selecting-course false))
      (when (. _G.just-pressed _G.control-map.left)
        (set _G.state.course-selected (math.max 1 (- _G.state.course-selected 1))))
      (when (. _G.just-pressed _G.control-map.right)
        (set _G.state.course-selected (math.min (# _G.state.course-select-items) (+ _G.state.course-selected 1)))))
    _G.state.menu-open
    (do
      (when (. _G.just-pressed _G.control-map.primary)
        (let [on-select (. _G.state.menu-items _G.state.menu-items-selected :on-select)]
          (on-select)))
      (when (. _G.just-pressed _G.control-map.secondary)
        (set _G.state.menu-open false))
      (when (. _G.just-pressed _G.control-map.up)
        (set _G.state.menu-items-selected (math.max 1 (- _G.state.menu-items-selected 1))))
      (when (. _G.just-pressed _G.control-map.down)
        (set _G.state.menu-items-selected (math.min (# _G.state.menu-items) (+ _G.state.menu-items-selected 1)))))
    ; else
    (do
      (when (. _G.just-pressed _G.control-map.primary)
        (set _G.state.menu-open true))))
  
  (lume.clear _G.just-pressed)
)

(fn love.keypressed [_key scancode _isrepeat]
  (tset _G.just-pressed scancode true))