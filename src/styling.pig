(module styling
  (:import
    [dom :from piglet:dom]
    ))

(defn css [v]
  (cond
    (dict? v)
    (join "\n"
      (for [[k v] v]
        (str (name k) ": " (css v) ";")))
    (vector? v)
    (let [sel (first v)
          more (rest v)
          dicts (filter dict? more)
          vects (filter vector? more)]
      (str (name sel) " {\n" (join "\n" (map css dicts)) "\n}\n"
        (join "\n"
          (for [v vects]
            (str (name sel) " " (css v))))))
    (list? v)
    (join "\n" (map css v))
    (identifier? v)
    (name v)
    :else
    v
    ))

(def style-el (dom:dom js:document [:style]))

(dom:append js:document.head style-el)

(defn style! [s]
  (set! (.-innerHTML style-el) (css s))
  nil)
