(module main
  (:import
    [scene :from scene]
    [solid :from solid:solid]
    [dom :from piglet:dom]
    [camera :from camera]
    [styles :from styles]
    [webaudio :from webaudio]
    [c :from components]
    [model :from model]
    [draggable :from draggable]
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

(defn center-pos [el]
  (let [rect (.getBoundingClientRect el)]
    (camera:vp->scene
      [(+ (.-x rect) (/ (.-width rect) 2))
       (+ (.-y rect) (/ (.-height rect) 2))])))

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
             (for [[cpx cpy x y] (butlast (get curve :curves))]
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
    [draggable:draggable
     {:init-pos (geom:point 0 0)}
     (solid:dom
       [:pre.osc
        "OSC\n"
        hz "Hz"
        "  " [connector wire-start]
        ])]))

(defn speaker []
  (solid:dom
    [draggable:draggable
     {:init-pos (geom:point 200 0)}
     (solid:dom
       [:pre.speaker
        "     _\n"
        "    /| · ⢁\n"
        [connector wire-end]
        " [⣿{  ⡇ ⡇\n"
        "    \\| · ⡈\n"
        "     `\n"
        ])]))

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
                                        (when (and
                                                (not @draggable:currently-dragging)
                                                (= 1 (.-buttons e)))
                                          (camera:move-by! [(.-movementX e)
                                                            (.-movementY e)]))))}
           ;; [osc-compo 330.5]
           ;; [speaker]
           ;; [wire wire-start wire-end]
           (for [c (keys (:nodes @model:graph))]
             [c:render c])
           ])]
       #_
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

(set!
  (.-required
    (ensure-module (fqn *current-module*)))
  true)
