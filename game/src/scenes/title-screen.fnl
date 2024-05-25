(set _G.title-screen-scene {})

(fn _G.title-screen-scene.unload []
  (love.audio.stop _G.title-screen-music))

(fn _G.title-screen-scene.load []
  (love.audio.play _G.title-screen-music)

  (set _G.state
  { :menu-open false
    :menu-items [{:text "Play game"
                  :on-select (fn []
                                (set _G.state.selecting-course true))}
                                {:text "Don't play game"
                                 :on-select (fn [] 
                                              (set _G.next-scene _G.not-playing-scene))}]
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

(fn _G.title-screen-scene.draw []
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
            (love.graphics.rectangle "fill" menu-offset-x menu-item-y (_G.font:getWidth (. _G.state.menu-items _G.state.menu-items-selected :text)) 15)
            (love.graphics.setColor (unpack (. _G.color-map :white)))
            (love.graphics.rectangle "line" menu-offset-x menu-item-y (_G.font:getWidth (. _G.state.menu-items _G.state.menu-items-selected :text)) 15))
          (love.graphics.setColor 1 1 1 1)
          (love.graphics.print v.text menu-offset-x menu-item-y))))
    ; else
    (do
      (let [text "Press [x] to start!"
            text-width (_G.font:getWidth text)
            text-x (math.floor (/ (- 240 text-width) 2))]
        (love.graphics.print text text-x 140)))))

(fn _G.title-screen-scene.update [dt]
  (if _G.state.selecting-course
    (do
      (when (. _G.just-pressed _G.control-map.primary)
        (love.audio.stop _G.menu-confirm-sound)
        (love.audio.play _G.menu-confirm-sound)
        (set _G.is-level-2 (= _G.state.course-selected 2))
        (set _G.next-scene _G.playing-course-scene))
      (when (. _G.just-pressed _G.control-map.secondary)
        (love.audio.stop _G.menu-decline-sound)
        (love.audio.play _G.menu-decline-sound)
        (set _G.state.selecting-course false))
      (when (. _G.just-pressed _G.control-map.left)
        (love.audio.stop _G.menu-hover-sound)
        (love.audio.play _G.menu-hover-sound)
        (set _G.state.course-selected (math.max 1 (- _G.state.course-selected 1))))
      (when (. _G.just-pressed _G.control-map.right)
        (love.audio.stop _G.menu-hover-sound)
        (love.audio.play _G.menu-hover-sound)
        (set _G.state.course-selected (math.min (# _G.state.course-select-items) (+ _G.state.course-selected 1)))))
    _G.state.menu-open
    (do
      (when (. _G.just-pressed _G.control-map.primary)
        (love.audio.stop _G.menu-confirm-sound)
        (love.audio.play _G.menu-confirm-sound)
        (let [on-select (. _G.state.menu-items _G.state.menu-items-selected :on-select)]
          (on-select)))
      (when (. _G.just-pressed _G.control-map.secondary)
        (love.audio.stop _G.menu-decline-sound)
        (love.audio.play _G.menu-decline-sound)
        (set _G.state.menu-open false))
      (when (. _G.just-pressed _G.control-map.up)
        (love.audio.stop _G.menu-hover-sound)
        (love.audio.play _G.menu-hover-sound)
        (set _G.state.menu-items-selected (math.max 1 (- _G.state.menu-items-selected 1))))
      (when (. _G.just-pressed _G.control-map.down)
        (love.audio.stop _G.menu-hover-sound)
        (love.audio.play _G.menu-hover-sound)
        (set _G.state.menu-items-selected (math.min (# _G.state.menu-items) (+ _G.state.menu-items-selected 1)))))
    ; else
    (do
      (when (. _G.just-pressed _G.control-map.primary)
        (love.audio.stop _G.menu-confirm-sound)
        (love.audio.play _G.menu-confirm-sound)
        (set _G.state.menu-open true)))))
