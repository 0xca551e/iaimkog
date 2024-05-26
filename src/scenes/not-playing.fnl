(require-macros :src.macros)

(set _G.not-playing-scene {})

(fn _G.not-playing-scene.unload [])

(fn _G.not-playing-scene.load []
  (love.audio.play _G.not-playing-music)
  (set _G.angy-timer 0))

(fn _G.not-playing-scene.draw []
  (love.graphics.draw _G.angy 94 64)
  (when (>= _G.angy-timer 2)
    (love.graphics.print "Fine." 110 60))
  (when (>= _G.angy-timer 5)
    (love.graphics.clear)))

(fn _G.not-playing-scene.update [dt]
  (+= _G.angy-timer dt)
  (when (>= _G.angy-timer 6)
    (love.event.quit)))
