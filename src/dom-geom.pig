(module dom-geom)

(extend-type js:DOMPointReadOnly
  Lookup
  (-get [this arg]
    (cond
      (= arg :x) (.-x this)
      (= arg :y) (.-y this)
      (= arg :z) (.-z this)
      (= arg :w) (.-w this)
      :else nil))
  (-get [this arg fallback]
    (cond
      (= arg :x) (.-x this)
      (= arg :y) (.-y this)
      (= arg :z) (.-z this)
      (= arg :w) (.-w this)
      :else fallback))
  Seqable
  (-seq [this]
    (list (.-x this) (.-y this) (.-z this) (.-w this))))

(extend-type js:DOMMatrixReadOnly
  Lookup
  (-get [this arg]
    (cond
      (= arg :a) (.-a this)
      (= arg :b) (.-b this)
      (= arg :c) (.-c this)
      (= arg :d) (.-d this)
      (= arg :e) (.-e this)
      (= arg :f) (.-f this)
      :else nil))
  (-get [this arg fallback]
    (cond
      (= arg :a) (.-a this)
      (= arg :b) (.-b this)
      (= arg :c) (.-c this)
      (= arg :d) (.-d this)
      (= arg :e) (.-e this)
      (= arg :f) (.-f this)
      :else fallback))
  Seqable
  (-seq [this]
    (list
      (.-a this)
      (.-b this)
      (.-c this)
      (.-d this)
      (.-e this)
      (.-f this))))

(defn point [& args]
  (if (= 1 (count args))
    (let [[arg] args]
      (cond
        (instance? js:DOMPointReadOnly arg)
        arg
        (sequential? arg)
        (apply point arg)
        (dict? arg)
        (js:DOMPointReadOnly.fromPoint (->js arg))))
    (new (js:Function.bind.apply js:DOMPointReadOnly
           (into-array (cons js:DOMPointReadOnly args))))))

(defn matrix [arg]
  (if (object? arg)
    (js:DOMMatrix.fromMatrix arg)
    (js:DOMMatrix. arg)))

(defn scale [scale]
  (matrix [scale 0 0 scale 0 0]))

(defn translate [x y]
  (matrix [1 0 0 1 x y]))

(defn m* [m & ms]
  (reduce (fn [a b] (.multiply a b)) m ms))

(defn m*p [m p]
  (.transformPoint m (point p)))

(defn m->css [m]
  (.toString m))
