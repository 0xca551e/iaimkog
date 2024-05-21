(set _G.util {})

(fn _G.util.concat-mut [t1 t2]
  (for [i 1 (# t2)]
    (tset t1 (+ (# t1) 1) (. t2 i)))
  t1)

(fn _G.util.range [start end step]
  (local result [])
  (for [i start end step]
    (table.insert result i))
  result)
(comment (_G.util.range 0 10 1))

(fn _G.util.debug [x]
  (print (inspect x))
  x)

(fn _G.util.window-by-2 [arr]
  (let [result {}]
    (for [i 1 (- (length arr) 1)]
      (table.insert result [(. arr i) (. arr (+ i 1))]))
    result))

(fn _G.util.sized-chunk [a n]
  (let [result {}]
    (for [i 1 (length a) n]
      (local chunk {})
      (for [j i (math.min (- (+ i n) 1) (length a))]
        (table.insert chunk (. a j)))
      (table.insert result chunk))
    result))
(comment (_G.util.sized-chunk [1 2 3 4 5] 2))

(fn _G.util.flatten [t]
  (lume.concat (unpack t)))

(fn _G.util.insertion-sort-by-mut [arr by-fn]
  (for [i 2 (length arr)]
    (local elem (. arr i))
    (var j (- i 1))
    (while (and (> j 0) (> (by-fn (. arr j) elem) (- 1)))
      (tset arr (+ j 1) (. arr j))
      (set j (- j 1)))
    (tset arr (+ j 1) elem)))
(comment
 (let [arr [5 2 4 6 1 3]]
   (_G.util.insertion-sort-by-mut arr (fn [a b] (- a b)))
   (print (inspect arr)))
 (let [arr [5 2 4 6 1 3]]
   (_G.util.insertion-sort-by-mut arr (fn [a b] (- b a)))
   (print (inspect arr)))
 (let [arr [{:x 5}
            {:x 2}
            {:x 4}
            {:x 6}
            {:x 1}
            {:x 3}]]
   (_G.util.insertion-sort-by-mut arr (fn [a b] (- a.x b.x)))
   (print (inspect arr))))

(fn _G.util.get [t f ...] (if (= nil f) t (_G.util.get (. t f) ...)))
(comment
 (_G.util.get [{:a {:b 123}}] 1 :a :b)
 (_G.util.get [{:a {:b 123}}] (unpack [1 :a :b])))

(fn _G.util.find-range [table min max min-get max-get]
  (var start-idx 1)
  (var end-idx (length table))
  (while (<= start-idx end-idx)
    (local mid (math.floor (/ (+ start-idx end-idx) 2)))
    (if (< (_G.util.get table mid (unpack min-get)) min) (set start-idx (+ mid 1))
        (set end-idx (- mid 1))))
  (local start-index start-idx)
  (set start-idx 1)
  (set end-idx (length table))
  (while (<= start-idx end-idx)
    (local mid (math.floor (/ (+ start-idx end-idx) 2)))
    (if (<= (_G.util.get table mid (unpack max-get)) max) (set start-idx (+ mid 1))
        (set end-idx (- mid 1))))
  (local end-index end-idx)
  [start-index end-index])
(comment
 (_G.util.find-range [4 5 6] 1 2 [] [])
 (_G.util.find-range [1
                   3
                   5
                   7
                   9
                   11
                   13
                   15]
                  5 11 [] [])
 (_G.util.find-range [{:min 1 :max 11 }
                   {:min 3 :max 13 }
                   {:min 5 :max 15 }
                   {:min 7 :max 17 }
                   {:min 9 :max 19 }
                   {:min 11 :max 111 }
                   {:min 13 :max 113 }
                   {:min 15 :max 115 }]
                     5 111 [:min] [:max]))