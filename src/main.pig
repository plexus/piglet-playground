(module main
  (:import
    [solid :from solid:solid]
    [dom :from piglet:dom]
    [styling :from styling]
    [webaudio :from webaudio]))

(styling:style!
  (list
    [:body {:background-color "#f5d576"
            :font-family "monospace"
            :overflow "hidden"
            :margin 0}]

    [:pre {:margin 0}]

    [:#app
     {:display :flex
      :width "100vw"
      :height "100vh"
      :justify-content :center
      :align-items :center}]

    [:.handle
     {:color "hsla(200, 20%, 70%)"
      :cursor "grab"
      :font-size "130%"}]
    [:.dragging {:cursor "grabbing"}]

    [:input
     {:width "30px"
      :height "200px"
      :padding "1rem"}]

    [:button
     {:font-size "1.5rem"
      :border "none"
      :border-radius "0.5rem"
      :box-shadow "rgba(100, 100, 111, 0.2) 0px 7px 29px 0px"}]

    [:.getting-started
     {:font-size "2rem"
      :padding "1rem 2rem"}]

    [:.stack
     {:display "flex"
      :flex-direction "column"
      :justify-contet "center"
      :text-align "center"}]

    [:.flex
     {:display "flex"}]))

(def sliders (solid:signal []))

(def slide-count (solid:reaction (count @sliders)))

(def slide-reactions
  (solid:reaction
    (for [idx (range @slide-count)]
      (solid:reaction
        (assoc (get @sliders idx) :idx idx)))))

(defn ctrl [idx]
  (solid:reaction (get-in @sliders [idx :val])))

(defn slider [opts]
  (let [opts @opts
        val (:val opts)
        min (:min opts 0)
        max (:max opts 1000)
        step (:step opts 1)
        label (:label opts)]
    (fn []
      (solid:dom
        [:div.stack
         [:div max]
         [:input {:type "range"
                  :min min
                  :max max
                  :orient "vertical"
                  :value val
                  :step step
                  :on-input (fn [e] (swap! sliders assoc-in [(:idx opts) :val]
                                      (js:parseFloat (.-value (.-target e)) 10)))}]
         [:div min]
         [:div label]]))))

(defn suspend-button []
  (let [susp? (solid:signal (webaudio:suspended?))]
    (solid:dom
      [:button {:on-click (do
                            (reset! susp? (not (webaudio:suspended?)))
                            (if (webaudio:suspended?)
                              (webaudio:resume!)
                              (webaudio:suspend!)))}
       (if @susp? [:span "▶️"] [:span "⏸️"])])))

(defn sliders-ui []
  (solid:dom
    [:div.flex
     (for [r @slide-reactions]
       [slider r])]))

(defmacro defonce [sym form]
  `(when (not (resolve '~sym))
     (def ~sym ~form)))

(defonce LISTENERS (js:Symbol (str `LISTENERS)))

(defn listen! [el k evt f]
  (when (not (oget el LISTENERS))
    (oset el LISTENERS (reference {})))
  (let [listeners (oget el LISTENERS)]
    (when-let [l (get-in @listeners [k evt])]
      (.removeEventListener el evt k))
    (swap! listeners assoc-in [k evt] f)
    (.addEventListener el evt f)))

(defn event-pos [e]
  (if-let [touches (.-touches e)]
    (let [touches (into-array touches)]
      (let [[x y] (reduce
                    (fn [[x y] touch]
                      [(+ x (.-clientX touch)) (+ y (.-clientY touch))])
                    [0 0]
                    touches)]
        [(/ x (count touches)) (/ y (count touches))]))
    [(.-clientX e) (.-clientY e)]))

(defn bounding-rect [el]
  (->pig (.getBoundingClientRect el)))

(def currently-dragging (reference nil))
(def zoom (solid:signal 1.5))

(defn rand-int [n]
  (js:Math.round (* n (js:Math.random))))

(defn handle-global-mouse-move [e]
  (when-let [el @currently-dragging]
    (if (= 0 (.-buttons e))
      (reset! currently-dragging nil)
      (let [handle (dom:query el ".handle")
            bounds (bounding-rect handle)
            [x y] (event-pos e)
            ;; Offset to middle of handle
            x (- x (/ (:width bounds) 2))
            y (- y (/ (:height bounds) 2))
            ;; Offset from middle of viewport
            vw2 (/ js:window.innerWidth 2)
            vh2 (/ js:window.innerHeight 2)
            x (- x vw2)
            y (- y vh2)
            ;; apply zoom
            x (/ x @zoom)
            y (/ y @zoom)
            ;; shift back
            x (+ x vw2)
            y (+ y vh2)]
        (println [x y] (:width bounds) (:height bounds))
        (dom:set-attr el
          :style {:position "absolute"
                  ;; :left (str (- x (/ (:width bounds) 2)) "px")
                  ;; :top (str (- y (/ (:height bounds) 2)) "px")
                  :transform (str "translate(" x "px" "," y "px" ")")
                  :left 0
                  :top 0
                  :user-select "none"})))))

(listen! js:document ::drag-component "mouseup" (fn [_] (reset! currently-dragging nil)))
(listen! js:document ::drag-component "mousemove" handle-global-mouse-move)
(listen! js:document ::drag-component "touchmove" handle-global-mouse-move)
(listen! js:document ::zoom "wheel"
  (fn [e]
    (println (.-deltaY e) @zoom)
    (swap! zoom (fn [z]
                  (max 0.1 (+ z (* (.-deltaY e) -0.0001)))))
    (.preventDefault e)))

(defn draggable [child]
  (solid:dom
    (let [dragstart (fn [e]
                      (.add (.-classList (.-target e)) "dragging")
                      (reset! currently-dragging (dom:parent (.-target e))))
          dragend  (fn [e]
                     (.remove (.-classList (.-target e)) "dragging")
                     (reset! currently-dragging nil)
                     (dom:set-attr (dom:parent (.-target e))
                       :style {:user-select "auto"}))
          self (solid:signal nil)]
      [:div {:style {:position "absolute"}
             :ref (fn [el]
                    (dom:set-attr el :style {:left (str (rand-int 500) "px")
                                             :top (str (rand-int 500) "px")}))}
       [:span.handle
        {
         :on-pointerdown dragstart
         :on-pointerup dragend}
        "⣿⣿"]
       child])))

(defn osc-compo [hz]
  (solid:dom
    [draggable
     (solid:dom
       [:pre
        "OSC\n"
        hz "Hz"
        "  ⚇"
        ])]))

(defn speaker []
  (solid:dom
    [draggable
     (solid:dom
       [:pre
        "     _\n"
        "    /|   ⢁ \n"
        "⚉ [⣿ } ⡱ ⡇ \n"
        "    \\|   ⡈ \n"
        "     `\n"
        ])])
  )

(defn ui []
  (solid:dom
    [:div {:style {:transform (str "scale(" @zoom ")")
                   :position "absolute"
                   :top 0
                   :left 0
                   :transform-origin "50vw 50vh"}}
     [osc-compo 330.5]
     [speaker]] )
  )

(defn app []
  (solid:dom
    (if (not @webaudio:ctx)
      [:button.getting-started {:on-click (webaudio:init!)}
       "Get started!"]
      [ui]
      )))

(solid:render
  (fn []
    (solid:dom [app]))
  (dom:el-by-id js:document "app"))

(doseq [[k v] webaudio]
  (.intern *current-module* (name k) @v))

(comment

  (swap! sliders conj {:min 0 :max 1 :step 0.01 :val 0 :label "MAIN"})
  (swap! sliders conj {:min 0 :max 200 :val 0 :label "LFO FREQ"})
  (swap! sliders conj {:min 0 :max 10 :val 0 :label "LFO DEPTH"})
  (swap! sliders conj {:min 50 :max 1000 :val 0 :label "FREQ"})

  (do @sliders)

  (def o
    (gain {:in
           (osc {:frequency (mix
                              (gain {:in (osc {:frequency (ctrl 1) :type "sine"})
                                     :gain (ctrl 2)})
                              (constant {:offset (ctrl 3)}))
                 :type "square"})
           :gain (ctrl 0)}))

  (plug m (dest))
  (plug o (dest))

  (unplug o (dest))
  (do @slider-value)

  (.start m)
  (.stop o)
  (.suspend @ctx)
  (.resume @ctx)
  )
