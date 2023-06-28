(module main
  (:import
    [solid :from solid:solid]
    [dom :from piglet:dom]
    [styling :from styling]
    [webaudio :from webaudio]))

(styling:style!
  (list
    [:body {:background-color "#f5d576"
            :font-family "serif"}]

    [:#app
     {:display :flex
      :width "100vw"
      :height "100vh"
      :justify-content :center
      :align-items :center}]

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
      :padding "1rem 2rem"
      }]))

(def sliders (solid:signal [{:min 0 :max 1000 :val 500}]))
(def slide-count (solid:reaction (println "count changed") (count @sliders)))
(def slide-reactions (solid:reaction
                       (println "slide-reactions")
                       (for [idx (range @slide-count)]
                         (solid:reaction
                           (println "inner slide-reaction")
                           (assoc (get @sliders idx) :idx idx)))))

(defn slider [opts]
  (println "UI" opts)
  (let [opts @opts
        val (:val opts)
        min (:min opts 0)
        max (:max opts 1000)]
    (fn []
      (solid:dom
        [:input {:type "range"
                 :min min
                 :max max
                 :orient "vertical"
                 :value val
                 :on-input (fn [e] (swap! sliders assoc-in [(:idx opts) :val]
                                     (js:parseInt (.-value (.-target e)) 10)))}]))))
(defn ui []
  (println "UI")
  (let [susp? (solid:signal (webaudio:suspended?))]
    (fn []
      (solid:dom
        [:div
         [:button {:on-click (do
                               (reset! susp? (not (webaudio:suspended?)))
                               (if (webaudio:suspended?)
                                 (webaudio:resume!)
                                 (webaudio:suspend!)))}
          (if @susp? [:span "▶️"] [:span "⏸️"])]
         (for [r @slide-reactions]
           [slider r])]))))

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
  (def o
    (osc {:frequency 400
          :type "square"}))

  (def m
    (mix
      (osc {:frequency 300
            :type "sine"})
      (osc {:frequency 500
            :type "sine"})))

  (def lfo-freq (solid:signal 5))
  (def lfo-gain (solid:signal 5))
  (def freq (solid:signal 200))

  (reset! freq -890)
  (reset! lfo-freq 2)
  (reset! lfo-gain 200)
  (reset!  200)

  (def o
    (osc {:frequency (mix
                       (gain {:in (osc {:frequency lfo-freq :type "sine"})
                              :gain lfo-gain})
                       (constant {:offset slider-value}))
          :type "square"}))

  (def o
    (osc {:frequency slider-value
          :type "sine"}))

  (plug m (dest))
  (plug o (dest))

  (unplug o (dest))
  (do @slider-value)

  (.start m)
  (.stop o)
  (.suspend @ctx)
  (.resume @ctx)
  )

:foo
:foo/bar
:foo/bar/baz
:foo/bar
:foo/bar/baz
