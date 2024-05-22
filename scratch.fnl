(do (set _G.ball {:position {:x 1  :y 0 :z 1.25}
                  :radius 0.25
                  :velocity {:x 0 :y 0 :z 0}
                  :variant :ball})
    (table.insert _G.drawables _G.ball))

(_G.camera.to-ball)
