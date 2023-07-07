(module camera
  (:import
    [solid :from solid:solid]
    [geom :from dom-geom]))

;; Mutable camera
(defonce camera (solid:signal (geom:ident)))

;; Pure functions over camera values
(defn viewport->scene [camera point]
  (geom:m*v (geom:inverse camera) point))

(defn scene->viewport [camera point]
  (geom:m*v camera point))

(defn css-transform [camera]
  (geom:m->css camera))

(defn css-translate [point]
  (str "translate(" (:x point) "px," (:y point) "px)"))

;; Functions that manipulate the camera reference
(defn update-camera! [& ms]
  (apply swap! camera geom:m* ms))

(defn vp->scene [pos]
  (camera:viewport->scene @camera:camera pos))

(defn scene->vp [pos]
  (camera:scene->viewport @camera:camera pos))

(defn zoom [] (:a @camera))

(defn set-zoom! [z]
  (swap! camera
    (fn [c] (geom:matrix [z (:b c) (:c c) z (:e c) (:f c)]))))

(defn set-pan-x! [x]
  (swap! camera
    (fn [c] (geom:matrix [(:a c) (:b c) (:c c) (:d c) x (:f c)]))))

(defn set-pan-y! [y]
  (swap! camera
    (fn [c] (geom:matrix [(:a c) (:b c) (:c c) (:d c) (:e c) y]))))

(defn zoom-by! [ratio p]
  (let [point (viewport->scene @camera (geom:point p))]
    (update-camera!
      (geom:translate (:x point) (:y point))
      (geom:scale (+ 1 ratio))
      (geom:translate (- (:x point)) (- (:y point))))))

(defn move-by! [[dx dy]]
  (update-camera! (geom:translate (/ dx (zoom)) (/ dy (zoom)))))

;; DOM integration

(defn wrap-camera [& children]
  (solid:dom
    [:div.camera {:style {:transform (camera:css-transform @camera:camera)
                          :transform-origin "0 0"
                          :position "absolute"
                          :top 0
                          :left 0}}
     (into-array children)]))
