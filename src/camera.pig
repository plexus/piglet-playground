(module camera
  (:import
    [solid :from solid:solid]))

(defonce camera (solid:signal {:zoom 1
                               :x 0
                               :y 0}))

(defn zoom [] (:zoom @camera))

(defn viewport->scene [camera [x y]]
  (let [zoom (:zoom camera)
        cx (:x camera)
        cy (:y camera)]
    [(/ (- x cx) zoom) (/ (- y cy) zoom)]))

(defn scene->viewport [camera [x y]]
  (let [zoom (:zoom camera)
        cx (:x camera)
        cy (:y camera)]
    [(+ (* x zoom) cx) (+ (* y zoom) cy)]))

(defn translate-pos [camera [x y]]
  (let [zoom (:zoom camera)
        cx (:x camera)
        cy (:y camera)]
    [(- x (/ cx zoom)) (- y (/ cy zoom))]
    ))

(defn css-transform [camera]
  (let [zoom (:zoom camera)
        cx (:x camera)
        cy (:y camera)]
    (str "translate(" cx "px," cy "px) scale(" zoom ")")))

(defn css-translate [[x y]]
  (str "translate(" x "px," y "px)"))

(defn zoom-by! [amount [x y]]
  (swap! camera (fn [c]
                  (let [new-zoom (max 0.1 (+ (:zoom c) amount))
                        new-c (assoc c :zoom new-zoom)
                        new-pos [(* x (/ new-zoom (:zoom c)))
                                 (* y (/ new-zoom (:zoom c)))]
                        dxs (- (first new-pos) x)
                        dys (- (second new-pos) y)]
                    {:zoom new-zoom
                     :x (- (:x c) (* dxs new-zoom))
                     :y (- (:y c) (* dys new-zoom))}))))

(defn move-by! [[dx dy]]
  (swap! camera (fn [c]
                  (-> c
                    (update :x + dx)
                    (update :y + dy)))))

(defn wrap-camera [& children]
  (solid:dom
    [:div.camera {:style {:transform (camera:css-transform @camera:camera)
                          :transform-origin "0 0"
                          :position "absolute"
                          :top 0
                          :left 0}}
     (into-array children)]))
