(require-macros :src.macros)

(set _G.level {})

(fn _G.level.make-tile [variant x y z]
  (table.insert _G.drawables {:variant variant :position {:x x :y y :z z} :draw-offset {:x 0 :y 0 :z 0}})
  (let [[tris edges verts] (. _G.tile-hitboxes variant)]
    (_G.util.concat-mut _G.tris (_G.geometry.translate-tris-and-add-aabb tris {:x x :y y :z z}))))

(fn _G.level.draw []
  ;; NOTE: the ball will move around affecting z index
  ;; since tables are references, we just make the ball itself a drawable in here
  (_G.util.insertion-sort-by-mut _G.drawables (fn [a b]
                                                (let [a-score (+ a.position.x a.position.y (* (+ a.position.z a.draw-offset.z) 16))
                                                      b-score (+ b.position.x b.position.y (* (+ b.position.z b.draw-offset.z) 16))]
                                                  (- a-score b-score))))
  (each [_ v (ipairs _G.drawables)]
    (let [[ix iy] (_G.geometry.to-isometric v.position.x v.position.y v.position.z)
          x (- ix _G.grid-size)
          y iy
          x2 (+ v.draw-offset.x x)
          y2 (+ v.draw-offset.y y)]
      (if v.animation
          (do
            (+= v.animation.timer (love.timer.getDelta))
            (let [animation-quads (. _G.animated-sprite-quads v.variant)
                  current-frame (-> v.animation.timer
                                    (/ v.animation.frame-duration)
                                    (% (# animation-quads))
                                    (math.floor)
                                    (+ 1))
                  current-quad (. animation-quads current-frame)]
              (love.graphics.draw _G.sprite-sheet current-quad x2 y2)))
          (love.graphics.draw _G.sprite-sheet (. _G.sprite-quads v.variant) x2 y2)))))

(fn _G.trim-whitespace [str] (str:gsub "^%s*(.-)%s*$" "%1"))
(comment
 (_G.trim-whitespace "   Hello, World!   "))

(fn _G.split-words [str]
  (let [words {}]
    (each [word (str:gmatch "%S+")]
      (table.insert words word))
    words))
(comment
 (_G.split-words " hello   world  this    is
   a test   "))

(fn _G.level.read-file-lines [filename]
  (each [line (io.lines filename)]
    (let [formatted-line (_G.trim-whitespace line)]
      (when (and (not= formatted-line "")
                 (not= (string.sub formatted-line 1 1) "#"))
        (let [[x y z hex] (_G.split-words formatted-line)
              color-name (. _G.color-names hex)
              tile (. _G.color-tile-map color-name)]
          (when tile
            (when (= tile :hole)
              (set _G.level-hole {:x (- (tonumber x)) :y (tonumber y) :z (tonumber z)}))
            (_G.level.make-tile tile (- (tonumber x)) (tonumber y) (* (tonumber z) _G.block-height))))))))
(comment
 (_G.level.read-file-lines "levels/test-level.txt"))
