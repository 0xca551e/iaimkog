(set _G.ball {:position {:x -15.5 :y -4 :z 0.25}
              :radius 0.25
              :velocity {:x 0 :y 0 :z 0}})

(_G.camera-to-ball)

(_G.generate-ball-preview)


(comment
 (_G.level.make-floor 10 -5 0)
 (_G.level.make-floor 10 -4 0)
 (_G.level.make-floor 10 -3 0)
 (_G.level.make-floor 10 -2 0)
 (_G.level.make-floor 10 -1 0)
 (_G.level.make-floor 10 0 0)
 (_G.level.make-floor 11 0 0)
 (_G.level.make-floor 12 0 0)
 (_G.level.make-hole 13 0 0)
 ;; (_G.level.make-floor 14 0 -4)
 ;; (_G.level.make-floor 13 1 -4)
 ;; (_G.level.make-floor 3 1 0)
 ;; (_G.level.make-floor 3 2 0)
 ;; (_G.level.make-floor 3 3 0)
 ;; (_G.level.make-floor 3 3 1)
 ;; (_G.level.make-floor 3 3 2)
 ;; (_G.level.make-floor 3 3 3)

 (_G.level.make-slope 10 1 0)
 (_G.level.make-slope 10 2 -1)
 (_G.level.make-slope 10 3 -2)
 (_G.level.make-slope 10 4 -3)
 (_G.level.make-slope 10 5 -4)

 (_G.level.make-floor 10 6 -5)
 (_G.level.make-floor 10 7 -5)
 (_G.level.make-floor 10 8 -5)
 (_G.level.make-floor 10 9 -5))
