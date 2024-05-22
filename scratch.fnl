(do (set _G.ball {:position {:x 1  :y 0 :z 1.25}
                  :radius 0.25
                  :velocity {:x 0 :y 0 :z 0}
                  :variant :ball})
    (table.insert _G.drawables _G.ball))

(_G.camera.to-ball)
(_G.camera.to-preview-tail)             

(tset _G.camera :target {:from {:x 0 :y 0}
                         :to {:x 100 :y 0}
                         :duration 0.5
                         :t 0
                         :easing _G.ease-in-out-cubic})

(_G.camera.set-target 100 0 1 _G.ease-in-out-cubic)
