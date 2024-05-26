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

(do
  ;; (set _G.current-hole n)
  (set _G.shot-no 0)
  (set _G.par 3)

  (set _G.tris [])
  (set _G.level-hole _G.vector.zero)
  (set _G.ball {:position _G.vector.zero
                :radius 0.25
                :velocity _G.vector.zero
                :variant :ball
                :animation {:timer 0
                            :frame-duration (/ 1 6)}
                :draw-offset {:x 8 :y 6 :z -0.75}
                :collided false
                :just-collided false
                :spin-x 0
                :spin-y 0})
  (tset _G.ball :last-settled-at _G.ball.position)
  (set _G.drawables [_G.ball])

  ;; (_G.level.read-file-lines "levels/u-shaped.txt")
  ;; (_G.level.read-file-lines "levels/behind-the-wall.txt)"
  ;; (_G.level.read-file-lines "levels/carved-hill.txt")
  ;; (_G.level.read-file-lines "levels/spiral-down.txt")
  ;; (_G.level.read-file-lines "levels/up-two-stairs.txt")
  ;; (_G.level.read-file-lines "levels/curve-up-the-stairs.txt")
  ;; (_G.level.read-file-lines "levels/neo-tower.txt")
  ;; (_G.level.read-file-lines "levels/pachinko.txt")
  (_G.level.read-file-lines "levels/halfpipe-with-hole.txt")
  ;; NOTE: the level is static, so we don't need to sort every frame.
  ;; in a later version this might change
  (_G.util.insertion-sort-by-mut _G.tris (fn [a b]
                                           (let [[tri-a aabb-a] a
                                                 [tri-b aabb-b] b]
                                             (- aabb-a.min.x aabb-b.min.x))))

  (set _G.shot.state "moving")

  ; (_G.generate-ball-preview)
  ; (_G.camera.to-preview-tail)
  (set _G.should-generate-ball-preview true))
