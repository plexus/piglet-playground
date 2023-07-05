(module main
  (:import
    [solid :from solid:solid]
    [dom :from piglet:dom]
    [camera :from camera]
    [styles :from styles]
    [webaudio :from webaudio]
    [c :from components]
    [solid-js :from "solid-js"]
    [solid-web :from "solid-js/web"]
    [catenary :from "/self/node_modules/catenary-curve/lib/catenary-curve.js"]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DOM/event/math helpers

(defn delta [[x y] [xx yy]]
  (js:Math.sqrt
    (+
      (js:Math.pow (- x xx) 2)
      (js:Math.pow (- y yy) 2))))

(defn vp->scene [pos]
  (camera:viewport->scene @camera:camera pos))

(defn scene->vp [pos]
  (camera:scene->viewport @camera:camera pos))

(defn event-pos [e]
  (if-let [touches (.-touches e)]
    (let [touches (into-array touches)]
      (let [[x y] (reduce
                    (fn [[x y] touch]
                      [(+ x (.-clientX touch)) (+ y (.-clientY touch))])
                    [0 0]
                    touches)]
        [(/ x (count touches)) (/ y (count touches))]))
    (vp->scene [(.-clientX e) (.-clientY e)])))

(defn bounding-rect [el]
  (let [rect (.getBoundingClientRect el)
        [x y] (vp->scene [(.-x rect) (.-y rect)])
        zoom (camera:zoom)]
    {:x x :y y
     :width (.-width rect)
     :height (.-height rect)}))

(defn center-pos [el]
  (let [rect (.getBoundingClientRect el)]
    (vp->scene
      [(+ (.-x rect) #_(/ (.-width rect) 2))
       (+ (.-y rect) #_(/ (.-height rect) 2))])))

(defn move-to [el x y]
  #_(let [[x y] (vp->scene [x y])])
  (dom:set-attr el :style {:transform (camera:css-translate [x y])})
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
              [x y] (event-pos e)]
          (println hrect [x y])
          (move-to el
            (- x (/ (:width hrect) 2))
            (- y (/ (:height hrect) 2)))
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
                                           (+
                                             (* 0.2 js:window.innerWidth)
                                             (* 0.6 (rand-int js:window.innerWidth)))
                                           (+
                                             (* 0.2 js:window.innerWidth)
                                             (* 0.6 (rand-int js:window.innerHeight)))))}
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
    [:span {:ref
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
          (let [[x1 y1] @start
                [x2 y2] @end
                curve (catenary:getCatenaryCurve
                        #js {:x x1 :y y1}
                        #js {:x x2 :y y2}
                        (* 1.1 (delta [x1 y1] [x2 y2])))]
            [:div
             (for [[cpx cpy x y] (cons [nil nil x1 y1] (oget curve :curves))]
               [:div.positioned
                {:style {:color (css-hsl (:color @wire-opts))
                         :transform (camera:css-translate [x y])}
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
                            (swap! camera:camera assoc :zoom (js:parseFloat (.-value (.-target e)))))}]
      [:button {:on-click (camera:zoom-by! 0.1 [0 0])} "+"]]

     [:div
      [:button {:on-click (camera:move-by! [-10 0])} "-"]
      [:label "x"]
      [:input {:style {:width "5em"}
               :value (:x @camera:camera)
               :on-change (fn [e]
                            (swap! camera:camera assoc :x (js:parseFloat (.-value (.-target e)))))}]
      [:button {:on-click (camera:move-by! [10 0])} "+"]]

     [:div
      [:button {:on-click (camera:move-by! [0 -10])} "-"]
      [:label "y"]
      [:input {:style {:width "5em"}
               :value (:y @camera:camera)
               :on-change (fn [e]
                            (swap! camera:camera assoc :y (js:parseFloat (.-value (.-target e)))))}]
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
