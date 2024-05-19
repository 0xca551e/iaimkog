(set _G.level {})

(fn _G.level.tile-with-hole []
  (let [position _G.vector.zero
        ur (_G.vector.add position {:x 1 :y 0 :z 0})
        ul position
        dl (_G.vector.add position {:x 0 :y 1 :z 0})
        dr (_G.vector.add position {:x 1 :y 1 :z 0})
        r (_G.vector.add position {:x 1 :y 0.5 :z 0})
        u (_G.vector.add position {:x 0.5 :y 0 :z 0})
        l (_G.vector.add position {:x 0 :y 0.5 :z 0})
        d (_G.vector.add position {:x 0.5 :y 1 :z 0})

        square-lines [[ur ul] [ul dl] [dl dr] [dr ur]]
        square-verts [ur ul dl dr]

        circle-verts (_G.geometry.make-circle-verts {:x 0.5 :y 0.5 :z 0} 0.3 12)
        circle-lines (_G.geometry.close-loop (_G.util.window-by-2 circle-verts))


        ;; [circle-dr circle-dl circle-ul circle-ur]
        circle-chunks (_G.util.sized-chunk circle-lines 3)
        circle-dr (. circle-chunks 1)
        circle-dl (. circle-chunks 2)
        circle-ul (. circle-chunks 3)
        circle-ur (. circle-chunks 4)
        ur-tris (_G.geometry.fan-tris ur (-> circle-ur
                                             (_G.geometry.prepend-point u)
                                             (_G.geometry.append-point r)))
        ul-tris (_G.geometry.fan-tris ul (-> circle-ul
                                             (_G.geometry.prepend-point l)
                                             (_G.geometry.append-point u)))
        dl-tris (_G.geometry.fan-tris dl (-> circle-dl
                                             (_G.geometry.prepend-point d)
                                             (_G.geometry.append-point l)))
        dr-tris (_G.geometry.fan-tris dr (-> circle-dr
                                             (_G.geometry.prepend-point r)
                                             (_G.geometry.append-point d)))

        hole-tris (-> circle-lines
                      (lume.map (fn [x]
                                  (_G.geometry.extrude-line-to-rect x {:x 0 :y 0 :z -0.5} true)))
                      (_G.util.flatten))

        ]
    ;; (print (inspect (_G.flatten circle-chunks)))
    ;; (print (inspect (lume.concat [r] circle-ur [u])))
    ;; (print (inspect circle-dl))
    ;; (print (inspect (lume.concat [[u (lume.first circle-ul)]]
    ;;                              circle-ul
    ;;                              [[l (lume.last circle-ul)]])))
    [(lume.concat ur-tris ul-tris dl-tris dr-tris hole-tris)
     (lume.concat square-lines circle-lines)
     (lume.concat square-verts circle-verts)
     ]))

(comment (_G.level.tile-with-hole _G.vector.zero))

(fn _G.level.generate-hitboxes [hitbox-tris]
  [hitbox-tris
   (-> hitbox-tris
       (lume.map (fn [tri]
                   [[tri.a tri.b]
                    [tri.b tri.c]
                    [tri.c tri.a]]))
       (_G.util.flatten))
   (-> hitbox-tris
       (lume.map (fn [tri]
                   [tri.a tri.b tri.c]))
       (_G.util.flatten))])


(fn _G.level.make-floor [x y z]
  (table.insert _G.tiles {:x x :y y :z z})
  (let [[tris edges verts] _G.tile-hitboxes.floor]
    (_G._G.util.concat-mut _G.tris (_G.geometry.translate-tris tris {:x x :y y :z z}))
    (_G._G.util.concat-mut _G.edges (_G.geometry.translate-edges edges {:x x :y y :z z}))
    (_G._G.util.concat-mut _G.verts (_G.geometry.translate-verts verts {:x x :y y :z z}))))

(fn _G.level.make-slope [x y z]
  (table.insert _G.slopes-dl {:x x :y y :z z})
  (let [[tris edges verts] _G.tile-hitboxes.slope-dl]
    (_G._G.util.concat-mut _G.tris (_G.geometry.translate-tris tris {:x x :y y :z z}))
    (_G._G.util.concat-mut _G.edges (_G.geometry.translate-edges edges {:x x :y y :z z}))
    (_G._G.util.concat-mut _G.verts (_G.geometry.translate-verts verts {:x x :y y :z z}))))

(fn _G.level.make-hole [x y z]
  (table.insert _G.hole-tiles {:x x :y y :z z})
  ;; (print (inspect _G.tile-hitboxes.floor-with-hole))
  (let [[tris edges verts] _G.tile-hitboxes.floor-with-hole]
    (_G._G.util.concat-mut _G.tris (_G.geometry.translate-tris tris {:x x :y y :z z}))
    (_G._G.util.concat-mut _G.edges (_G.geometry.translate-edges edges {:x x :y y :z z}))
    (_G._G.util.concat-mut _G.verts (_G.geometry.translate-verts verts {:x x :y y :z z}))))

(fn _G.level.draw-floor [x y z]
  (let [[ix iy] (_G.geometry.to-isometric x y z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "floor") (- ix _G.grid-size) iy)))

(fn _G.level.draw-hole [x y z]
  (let [[ix iy] (_G.geometry.to-isometric x y z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "hole-tile") (- ix _G.grid-size) iy)))

(fn _G.level.draw-slopes [x y z]
  (let [[ix iy] (_G.geometry.to-isometric x y z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "slope-dl") (- ix _G.grid-size) iy)))

(fn _G.level.draw-ball []
  (let [[ix iy] (_G.geometry.to-isometric _G.ball.position.x _G.ball.position.y _G.ball.position.z)]
    (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads "ball") (- ix 8) (- iy 10))))
