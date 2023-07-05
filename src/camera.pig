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

(let [zoom 1
      ratio 1.41
      new-zoom (* zoom ratio)
      [fixed-point-x fixed-point-y] [100 100]
      [offset-x offset-y] [0 0]]
  [(- offset-x (- fixed-point-x (/ fixed-point-x new-zoom)))
   (- offset-y (- fixed-point-x (/ fixed-point-x new-zoom)))])

(defn zoom-by! [ratio [fixed-point-x fixed-point-y]]
  (println ratio [fixed-point-x fixed-point-y]
    [(:x @camera) (:y @camera)])
  (swap! camera
    (fn [c]
      (let [ratio (+ 1 ratio)
            zoom (:zoom c)
            new-zoom (* zoom ratio)
            offset-x (:x c)
            offset-y (:y c)]
        {:zoom new-zoom
         :x (- offset-x (- fixed-point-x (/ fixed-point-x new-zoom)))
         :y (- offset-y (- fixed-point-x (/ fixed-point-x new-zoom)))}
        ))))

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
