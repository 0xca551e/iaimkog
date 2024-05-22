(set _G.camera-speed 3)

(set _G.block-height 0.5)
(set _G.face-thickness 0.125)

(set _G.control-map {:left "left"
                  :right "right"
                  :up "up"
                  :down "down"
                  :fine-tune "lshift"
                  :secondary "z"
                  :primary "x"
                  :tertiary "c"})

  (set _G.scale 3)
  (set _G.grid-size 16)
  (set _G.tile-width 32)
  (set _G.tile-height 16)
  (set _G.gravity 0.1)
  (set _G.friction 0.5)
  (set _G.elasticity 0.8)
(set _G.shot-meter-max-time 1.5)

(set _G.sprite-sheet (love.graphics.newImage "sprites/spritesheet.png"))
(set _G.bg1 (love.graphics.newImage "sprites/bg1.png"))
(set _G.bg2 (love.graphics.newImage "sprites/bg2.png"))

(set _G.sprite-quads {})
(-> [[:floor 0 0 32 32]
     [:slope-r 1 0 32 32]
     [:slope-d 2 0 32 32]
     [:slope-l 3 0 32 32]
     [:slope-u 4 0 32 32]
     [:hole 0 1 32 32]
     [:slope-out-dr 1 1 32 32]
     [:slope-out-dl 2 1 32 32]
     [:slope-out-ul 3 1 32 32]
     [:slope-out-ur 4 1 32 32]
     [:slope-in-dr 1 2 32 32]
     [:slope-in-dl 2 2 32 32]
     [:slope-in-ul 3 2 32 32]
     [:slope-in-ur 4 2 32 32]]
    (lume.each (fn [[id gx gy sw sh]]
                (tset _G.sprite-quads id
                      (love.graphics.newQuad
                       (* 32 gx)
                       (* 32 gy)
                       sw
                       sh
                       (_G.sprite-sheet:getDimensions))))))

(set _G.animated-sprite-quads {})
(-> [[:ball 0 3 18 18 4]]
    (lume.each (fn [[id gx gy sw sh f]]
                 (tset _G.animated-sprite-quads id
                       (-> (_G.util.range 1 f 1)
                           (lume.map (fn [f]
                                       (love.graphics.newQuad
                                        (+ (* 32 gx) (* sw (- f 1)))
                                        (* 32 gy)
                                        sw
                                        sh
                                        (_G.sprite-sheet:getDimensions)))))))))

(fn _G.--generate-hitboxes [hitbox-tris]
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

(fn _G.--tile-with-hole []
  (let [position {:x 0 :y 0 :z 0}
        ur (_G.vector.add position {:x 1 :y 0 :z 1})
        ul position
        dl (_G.vector.add position {:x 0 :y 1 :z 1})
        dr (_G.vector.add position {:x 1 :y 1 :z 1})
        r (_G.vector.add position {:x 1 :y 0.5 :z 1})
        u (_G.vector.add position {:x 0.5 :y 0 :z 1})
        l (_G.vector.add position {:x 0 :y 0.5 :z 1})
        d (_G.vector.add position {:x 0.5 :y 1 :z 1})

        square-lines [[ur ul] [ul dl] [dl dr] [dr ur]]
        square-verts [ur ul dl dr]

        circle-verts (_G.geometry.make-circle-verts {:x 0.5 :y 0.5 :z 1} 0.3 12)
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
    [(lume.concat ur-tris ul-tris dl-tris dr-tris hole-tris)
    ;  (lume.concat square-lines circle-lines)
    ;  (lume.concat square-verts circle-verts)
     ]))

(comment (_G.--tile-with-hole))

(set _G.tile-hitboxes
     {:floor (_G.--generate-hitboxes (-> [(_G.geometry.rect-tris {:x 0 :y 0 :z 1}
                                                                 {:x 1 :y 0 :z 1}
                                                                 {:x 0 :y 1 :z 1}
                                                                 {:x 1 :y 1 :z 1})
                                          (_G.geometry.rect-tris {:x 1 :y 0 :z 1}
                                                                 {:x 0 :y 0 :z 1}
                                                                 {:x 1 :y 0 :z (- 1 _G.block-height)}
                                                                 {:x 0 :y 1 :z (- 1 _G.block-height)})
                                          (_G.geometry.rect-tris {:x 1 :y 1 :z 1}
                                                                 {:x 1 :y 0 :z 1}
                                                                 {:x 1 :y 1 :z (- 1 _G.block-height)}
                                                                 {:x 1 :y 0 :z (- 1 _G.block-height)})
                                          (_G.geometry.rect-tris {:x 0 :y 1 :z 1}
                                                                 {:x 1 :y 1 :z 1}
                                                                 {:x 0 :y 1 :z (- 1 _G.block-height)}
                                                                 {:x 1 :y 1 :z (- 1 _G.block-height)})
                                          (_G.geometry.rect-tris {:x 0 :y 0 :z 1}
                                                                 {:x 0 :y 1 :z 1}
                                                                 {:x 0 :y 0 :z (- 1 _G.block-height)}
                                                                 {:x 0 :y 1 :z (- 1 _G.block-height)})]
                                         (util.flatten)))
      :hole (_G.--tile-with-hole _G.vector.zero)
      :slope-in-dr (_G.--generate-hitboxes [{:a {:x 0 :y 0 :z 1}
                                                    :b {:x 1 :y 1 :z (- 1 _G.block-height)}
                                                    :c {:x 0 :y 1 :z 1}}
                                                   {:a {:x 0 :y 0 :z 1}
                                                    :b {:x 1 :y 0 :z 1}
                                                    :c {:x 1 :y 1 :z (- 1 _G.block-height)}}])
      :slope-in-dl (_G.--generate-hitboxes [{:a {:x 1 :y 0 :z 1}
                                                    :b {:x 0 :y 1 :z (- 1 _G.block-height)}
                                                    :c {:x 0 :y 0 :z 1}}
                                                   {:a {:x 1 :y 0 :z 1}
                                                    :b {:x 1 :y 1 :z 1}
                                                    :c {:x 0 :y 1 :z (- 1 _G.block-height)}}])
      :slope-in-ul (_G.--generate-hitboxes [{:a {:x 1 :y 1 :z 1}
                                                    :b {:x 0 :y 0 :z (- 1 _G.block-height)}
                                                    :c {:x 1 :y 0 :z 1}}
                                                   {:a {:x 1 :y 1 :z 1}
                                                    :b {:x 0 :y 1 :z 1}
                                                    :c {:x 0 :y 0 :z (- 1 _G.block-height)}}])
      :slope-in-ur (_G.--generate-hitboxes [{:a {:x 0 :y 1 :z 1}
                                                    :b {:x 1 :y 0 :z (- 1 _G.block-height)}
                                                    :c {:x 1 :y 1 :z 1}}
                                                   {:a {:x 0 :y 1 :z 1}
                                                    :b {:x 0 :y 0 :z 1}
                                                    :c {:x 1 :y 0 :z (- 1 _G.block-height)}}])
      :slope-r (_G.--generate-hitboxes (_G.geometry.rect-tris {:x 0 :y 0 :z 1}
                                                                     {:x 1 :y 0 :z (- 1 _G.block-height)}
                                                                     {:x 0 :y 1 :z 1}
                                                                     {:x 1 :y 1 :z (- 1 _G.block-height)}))
      :slope-d (_G.--generate-hitboxes (_G.geometry.rect-tris {:x 0 :y 0 :z 1}
                                                                     {:x 1 :y 0 :z 1}
                                                                     {:x 0 :y 1 :z (- 1 _G.block-height)}
                                                                     {:x 1 :y 1 :z (- 1 _G.block-height)}))
      :slope-l (_G.--generate-hitboxes (_G.geometry.rect-tris {:x 0 :y 0 :z (- 1 _G.block-height)}
                                                                     {:x 1 :y 0 :z 1}
                                                                     {:x 0 :y 1 :z (- 1 _G.block-height)}
                                                                     {:x 1 :y 1 :z 1}))
      :slope-u (_G.--generate-hitboxes (_G.geometry.rect-tris {:x 0 :y 0 :z (- 1 _G.block-height)}
                                                                     {:x 1 :y 0 :z (- 1 _G.block-height)}
                                                                     {:x 0 :y 1 :z 1}
                                                                     {:x 1 :y 1 :z 1}))
      :slope-out-dr (_G.--generate-hitboxes [{:a {:x 0 :y 0 :z 1}
                                                     :b {:x 1 :y 1 :z (- 1 _G.block-height)}
                                                     :c {:x 0 :y 1 :z (- 1 _G.block-height)}}
                                                    {:a {:x 0 :y 0 :z 1}
                                                     :b {:x 1 :y 0 :z (- 1 _G.block-height)}
                                                     :c {:x 1 :y 1 :z (- 1 _G.block-height)}}])
      :slope-out-dl (_G.--generate-hitboxes [{:a {:x 1 :y 0 :z 1}
                                                     :b {:x 0 :y 1 :z (- 1 _G.block-height)}
                                                     :c {:x 0 :y 0 :z (- 1 _G.block-height)}}
                                                    {:a {:x 1 :y 0 :z 1}
                                                     :b {:x 1 :y 1 :z (- 1 _G.block-height)}
                                                     :c {:x 0 :y 1 :z (- 1 _G.block-height)}}])
      :slope-out-ul (_G.--generate-hitboxes [{:a {:x 1 :y 1 :z 1}
                                                     :b {:x 0 :y 0 :z (- 1 _G.block-height)}
                                                     :c {:x 1 :y 0 :z (- 1 _G.block-height)}}
                                                    {:a {:x 1 :y 1 :z 1}
                                                     :b {:x 0 :y 1 :z (- 1 _G.block-height)}
                                                     :c {:x 0 :y 0 :z (- 1 _G.block-height)}}])
      :slope-out-ur (_G.--generate-hitboxes [{:a {:x 0 :y 1 :z 1}
                                                     :b {:x 1 :y 0 :z (- 1 _G.block-height)}
                                                     :c {:x 1 :y 1 :z (- 1 _G.block-height)}}
                                                    {:a {:x 0 :y 1 :z 1}
                                                     :b {:x 0 :y 0 :z (- 1 _G.block-height)}
                                                     :c {:x 1 :y 0 :z (- 1 _G.block-height)}}])
      })


(set _G.color-tile-map
     {:black :hole
      ;; :valhalla :unused
      ;; :loulou :unused
      ;; :oiled-cedar :unused
      ;; :rope :unused
      ;; :tahiti-gold :unused
      ;; :twine :unused
      ;; :pancho :unused
      ;; :golden-fizz :unused
      ;; :atlantis :unused
      ;; :christi :unused
      ;; :elf-green :unused
      ;; :dell :unused
      ;; :verdigris :unused
      ;; :opal :unused
      ;; :deep-koamaru :unused
      ;; :venice-blue :unused
      :royal-blue :slope-in-dr
      :cornflower :slope-in-dl
      :viking :slope-in-ul
      :light-steel-blue :slope-in-ur
      :white :floor
      :heather :slope-r
      :topaz :slope-d
      :dim-gray :slope-l
      :smokey-ash :slope-u
      :clairvoyant :slope-out-dr
      :brown :slope-out-dl
      :mandy :slope-out-ul
      :plum :slope-out-ur
      ;; :rain-forest :unused
      ;; :stinger :unused
      })

(set _G.color-names
     {"000000" :black
      "222034" :valhalla
      "45283c" :loulou
      "663931" :oiled-cedar
      "8f563b" :rope
      "df7126" :tahiti-gold
      "d9a066" :twine
      "eec39a" :pancho
      "fbf236" :golden-fizz
      "99e550" :atlantis
      "6abe30" :christi
      "37946e" :elf-green
      "4b692f" :dell
      "524b24" :verdigris
      "323c39" :opal
      "3f3f74" :deep-koamaru
      "306082" :venice-blue
      "5b6ee1" :royal-blue
      "639bff" :cornflower
      "5fcde4" :viking
      "cbdbfc" :light-steel-blue
      "ffffff" :white
      "9badb7" :heather
      "847e87" :topaz
      "696a6a" :dim-gray
      "595652" :smokey-ash
      "76428a" :clairvoyant
      "ac3232" :brown
      "d95763" :mandy
      "d77bba" :plum
      "8f974a" :rain-forest
      "8a6f30" :stinger})
