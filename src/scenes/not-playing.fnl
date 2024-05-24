(require-macros :src.macros)

(set _G.not-playing-scene {})

(fn _G.not-playing-scene.unload [])

(fn _G.not-playing-scene.load []
  (set _G.angy-timer 0))

(fn _G.not-playing-scene.draw []
  (love.graphics.draw _G.angy 94 64)
  (when (>= _G.angy-timer 2)
    (love.graphics.print "Fine." 110 60)))

(fn _G.not-playing-scene.update [dt]
  (+= _G.angy-timer dt)
  (when (>= _G.angy-timer 5)
    (love.event.quit)))
