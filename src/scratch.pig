
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
