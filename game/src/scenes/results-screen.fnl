(require-macros :src.macros)

(set _G.result-screen-scene {})

(fn _G.result-screen-scene.unload []
  (love.audio.stop _G.title-screen-music))

(fn _G.result-screen-scene.load []
  (love.audio.play _G.title-screen-music))

(fn _G.result-screen-scene.draw []
  (if _G.is-level-2
    (love.graphics.draw _G.bg2)
    (love.graphics.draw _G.bg1))
  (love.graphics.setColor 0 0 0 0.2)
  (love.graphics.rectangle "fill" 0 0 240 160)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.printf "You did it!" 0 10 240 "center")
  (love.graphics.printf "Hole:" 0 40 60 "right")
  (love.graphics.printf "Par:" 0 60 60 "right")
  (love.graphics.printf "You:" 0 80 60 "right")
  (each [i v (ipairs _G.course-scores)]
    (love.graphics.print i (+ 70 (* (- i 1) 18)) 40)
    (love.graphics.print (.. (tostring v)) (+ 70 (* (- i 1) 18)) 80))
  (each [i v (ipairs _G.course-hole-pars)]
    (love.graphics.print (.. (tostring v)) (+ 70 (* (- i 1) 18)) 60))
  (love.graphics.printf (.. "Final score: " (tostring (lume.reduce _G.course-scores (fn [acc x] (+ acc x)) 0))) 0 110 240 "center")
  (love.graphics.printf "Press [X] to continue" 0 140 240 "center"))
(fn _G.result-screen-scene.update []
  (when (love.keyboard.isDown (. _G.control-map :primary))
    (love.audio.stop _G.menu-confirm-sound)
    (love.audio.play _G.menu-confirm-sound)
    (set _G.next-scene _G.title-screen-scene)))
