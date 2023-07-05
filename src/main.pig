(module main
  (:import
    [solid :from solid:solid]
    [dom :from piglet:dom]
    [camera :from camera]
    [styles :from styles]
    [webaudio :from webaudio]
    [c :from components]
    [geom :from dom-geom]
    [solid-js :from "solid-js"]
    [solid-web :from "solid-js/web"]
    [catenary :from "/self/node_modules/catenary-curve/lib/catenary-curve.js"]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOM/event/math helpers

(defn delta [p1 p2]
  (js:Math.sqrt
    (+
      (js:Math.pow (- (:x p1) (:x p2)) 2)
      (js:Math.pow (- (:y p1) (:y p2)) 2))))

(defn vp->scene [pos]
  (camera:viewport->scene @camera:camera pos))

(defn scene->vp [pos]
  (camera:scene->viewport @camera:camera pos))

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

(defn center-pos [el]
  (let [rect (bounding-rect el)]
    (vp->scene
      [(+ (.-x rect) (/ (.-width rect) 2))
       (+ (.-y rect) (/ (.-height rect) 2))])))

(defn move-to [el point]
  (dom:set-attr el :style {:transform (camera:css-translate point)})
  (let [event (js:CustomEvent. "position-changed" #js {:bubbles "false"})]
    ((fn dispatch [el]
       (.dispatchEvent el event)
       (run! dispatch (into-array (dom:children el)))) el)))

(defmacro defcomponent [comp-name argv & body]
  (let [add-class (fn add-class [form]
                    (cond
                      (vector? form)
                      (if (keyword? (first form))
                        `[~(keyword (str (name (first form)) "." comp-name))
                          ~@(rest form)]
                        form)
                      (list? form)
                      `(~@(butlast form) ~(add-class (last form)))
                      :else
                      form))]
    `(defn ~comp-name ~argv
       ~@(butlast body)
       (solid:dom ~(add-class (last body))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; draggable

(def currently-dragging (reference nil))

(defn handle-global-mouse-move [e]
  (if-let [el @currently-dragging]
    (if (= 0 (.-buttons e))
      (reset! currently-dragging nil)
      (when-let [handle (dom:query el ".handle")]
        (let [hrect (bounding-rect handle)
              point (event-pos e)]
          (move-to el (vp->scene (geom:p+
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

(defn draggable [child]
  (solid:dom
    (let [dragstart (fn [e]
                      (.add (.-classList (.-target e)) "dragging")
                      (reset! currently-dragging (dom:parent (.-target e))))
          dragend  (fn [e]
                     (.remove (.-classList (.-target e)) "dragging")
                     (reset! currently-dragging nil))]
      [:div.draggable.positioned {:ref (fn [el]
                                         (move-to el
                                           (vp->scene [
                                                       (+
                                                         (* 0.2 js:window.innerWidth)
                                                         (* 0.6 (rand-int js:window.innerWidth)))
                                                       (+
                                                         (* 0.2 js:window.innerWidth)
                                                         (* 0.6 (rand-int js:window.innerHeight)))])))}
       [:span.handle
        {:on-pointerdown dragstart
         :on-pointerup dragend}
        "⣿⣿"]
       child])))

;; /draggable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wire

(def wire-start (solid:signal nil))
(def wire-end (solid:signal nil))
(def inspect-self (solid:signal nil))

(defn connector [ref]
  (solid:dom
    [:span.connector
     {:ref
      (fn [self]
        (reset! inspect-self self)
        (js:requestAnimationFrame
          (fn []
            (when (not @ref)
              (reset! ref (center-pos self))))))
      :on-position-changed
      (fn [e]
        (reset! ref (center-pos (.-target e))))} "⚇"]))

(defn css-hsl [[deg sat light]]
  (str "hsl(" deg "," sat "%,", light "%)"))

(defn rand-hsl []
  [(rand-int 360) (rand-int 100) (rand-int 100)])

(defn wire [start end]
  (let [wire-opts (solid:signal {:color (rand-hsl)
                                 :glyph (rand-nth "⚬⦁⦂⚲☌◦◌⏺⎊⎉⎈⍤" )})]
    (solid:dom
      [:div.wire.positioned
       (if (and @start @end)
         [:div
          (let [curve (catenary:getCatenaryCurve
                        @start
                        @end
                        (* 1.1 (delta @start @end) (max 1 (/ 500 (delta @start @end)))))]
            [:div
             (for [[cpx cpy x y] (butlast (oget curve :curves))]
               [:div.positioned.segment
                {:style {:color (css-hsl (:color @wire-opts))
                         :transform (camera:css-translate (geom:point x y))}
                 :on-click (reset! wire-opts {:color (rand-hsl)
                                              :glyph (rand-nth "⚬⦁⦂⚲☌◦◌⏺⎊⎉⎈⍤" )})}
                (:glyph @wire-opts)])])]
         [:div.wire])])))
;; /wire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn camera-controls []
  (solid:dom
    [:div.positioned
     [:div
      [:button {:on-click (camera:zoom-by! -0.1 [0 0])} "-"]
      [:label "zoom"]
      [:input {:style {:width "5em"}
               :value (camera:zoom)
               :on-change (fn [e]
                            (camera:set-zoom! (js:parseFloat (.-value (.-target e)))))}]
      [:button {:on-click (camera:zoom-by! 0.1 [0 0])} "+"]]

     [:div
      [:button {:on-click (camera:move-by! [-10 0])} "-"]
      [:label "x"]
      [:input {:style {:width "5em"}
               :value (:e @camera:camera)
               :on-change (fn [e]
                            (camera:set-pan-x! (js:parseFloat (.-value (.-target e)))))}]
      [:button {:on-click (camera:move-by! [10 0])} "+"]]

     [:div
      [:button {:on-click (camera:move-by! [0 -10])} "-"]
      [:label "y"]
      [:input {:style {:width "5em"}
               :value (:f @camera:camera)
               :on-change (fn [e]
                            (camera:set-pan-y! (js:parseFloat (.-value (.-target e)))))}]
      [:button {:on-click (camera:move-by! [0 10])} "+"]]
     ]))


(defn osc-compo [hz]
  (solid:dom
    [draggable
     (solid:dom
       [:pre.osc
        "OSC\n"
        hz "Hz"
        "  " [connector wire-start]
        ])]))

(defn speaker []
  (solid:dom
    [draggable
     (solid:dom
       [:pre.speaker
        "     _\n"
        "    /| · ⢁\n"
        [connector wire-end]
        " [⣿{  ⡇ ⡇\n"
        "    \\| · ⡈\n"
        "     `\n"
        ])]))

(defn posinfo [el]
  (when el
    (let [rect (.getBoundingClientRect el)]
      {:bounds
       {:x (.-x rect)
        :y (.-y rect)
        :width (.-width rect)
        :height (.-height rect)}
       :scene
       {:vp->scene (vp->scene [(.-x rect) (.-y rect)])
        }})))

(defn inspect-pos []
  (let [info (solid:signal nil)]
    (solid:dom
      [draggable
       (solid:dom
         [:div {:ref
                (fn [s]
                  ;; (reset! inspect-self s)
                  (reset! info (posinfo @inspect-self)))
                :on-position-changed
                (fn [e] (reset! info (posinfo @inspect-self)))
                :on-click
                (fn [e] (reset! info (posinfo @inspect-self)))}
          (for [[head kvs] @info]
            [:div
             [:h5 (str head)]
             (for [[k v] kvs]
               [:p (str k) "=" (str v)])])]
         )])))

(defn inspect-pane [info]
  (solid:dom
    [draggable
     (solid:dom
       [:div
        (for [[head kvs] @info]
          [:div
           [:h5 (str head)]
           (for [[k v] kvs]
             [:p (str k) "=" (str v)])])])]))

(defn ui []
  (let [panning? (solid:signal false)]
    (solid:dom
      [:div
       [camera:wrap-camera
        (solid:dom
          [:div.ui {:class (if @panning? ["dragging"] [""])
                    :on-pointerdown (fn [_] (reset! panning? true))
                    :on-pointerup (fn [_] (reset! panning? false))
                    :on-pointermove (fn [e]
                                      (let [self (.-target e)]
                                        (when (and (not @currently-dragging)
                                        (= 1 (.-buttons e)))
                                          (camera:move-by! [(.-movementX e)
                                                            (.-movementY e)]))))}
           [inspect-pos]
           [osc-compo 330.5]
           [speaker]
           [wire wire-start wire-end]
           ])]
       [camera-controls]])))

(solid:render
  (fn []
    (solid:dom [:div.app
                (if (not @webaudio:ctx)
                  [:button.getting-started {:on-click (webaudio:init!)}
                   "Get started!"]
                  [ui])]))
  (dom:el-by-id js:document "app"))

(doseq [[k v] webaudio]
  (.intern *current-module* (name k) @v))
