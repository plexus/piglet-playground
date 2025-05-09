(module draggable
  (:import
    [solid :from solid:solid]
    [geom :from dom-geom]
    [dom :from piglet:dom]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; draggable

(def currently-dragging (box nil))

(defn event-pos [e]
  (geom:point
    (if-let [touches (.-touches e)]
      (let [touches (into-array touches)
            [x y] (reduce
                    (fn [[x y] touch]
                      [(+ x (.-clientX touch)) (+ y (.-clientY touch))])
                    [0 0]
                    touches)]
        [(/ x (count touches)) (/ y (count touches))])
      [(.-clientX e) (.-clientY e)])))

(defn bounding-rect [el]
  (.getBoundingClientRect el))

(defn move-to [el point]
  (dom:set-attr el :style {:transform (camera:css-translate point)})
  (let [event (js:CustomEvent. "position-changed" #js {:bubbles "false"})]
    ((fn dispatch [el]
       (.dispatchEvent el event)
       (run! dispatch (into-array (dom:children el)))) el)))

(defn handle-global-mouse-move [e]
  (when-let [el @currently-dragging]
    (if (= 0 (.-buttons e))
      (reset! currently-dragging nil)
      (when-let [handle (dom:query-one el ".handle")]
        (let [hrect (bounding-rect handle)
              point (event-pos e)]
          (move-to el (camera:vp->scene (geom:p+
                                          point
                                          (geom:p*
                                     (geom:point (:width hrect) (:height hrect))
                                     0.5))))
          (.stopImmediatePropagation e))))))

(defn handle-scrollwheel-zoom [e]
  (camera:zoom-by! (* (.-deltaY e) -0.0001) [(.-clientX e) (.-clientY e)])
  (.preventDefault e))

(dom:listen! js:document ::drag-component "mouseup" (fn [_] (reset! currently-dragging nil)))
(dom:listen! js:document ::drag-component "mousemove" (resolve 'handle-global-mouse-move))
(dom:listen! js:document ::drag-component "touchmove" (resolve 'handle-global-mouse-move))
(dom:listen! js:document ::zoom "wheel" (resolve 'handle-scrollwheel-zoom))

(defn draggable [props child]
  (let [dragstart (fn [x]
                    (.add (.-classList (.-target x)) "dragging")
                    (reset! currently-dragging (dom:parent (.-target x))))
        dragend  (fn [x]
                   (.remove (.-classList (.-target x)) "dragging")
                   (reset! currently-dragging nil))
        pos-handler (:on-position-changed props)]
    (solid:dom
      [:div.draggable.positioned
       {:ref (fn [el] (move-to el (:init-pos props)))
        :on-position-changed (if pos-handler pos-handler identity)}
       [:span.handle
        {:on-pointerdown dragstart
         :on-pointerup dragend}
        "⣿⣿"]
       child])))
