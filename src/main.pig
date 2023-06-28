(module main
  (:import
    [solid :from solid:solid]
    [dom :from piglet:dom]
    [styling :from styling]
    [webaudio :from webaudio])
  (:context {"user" "https://vocab.gaiwan.co/user#"}))

(inspect
  :user:name)

(:user:name
  {:user:name "Arne"})

:co.gaiwan.user/name

(styling:style!
  (list
    [:body {:background-color "#f5d576" :font-family "serif"}]

    [:#app
     {:display :flex
      :width "100vw"
      :height "100vh"
      :justify-content :center
      :align-items :center}]

    [:.getting-started
     {:font-size "2rem"
      :padding "1rem 2rem"
      :border "none"
      :border-radius "0.5rem"
      :box-shadow "rgba(100, 100, 111, 0.2) 0px 7px 29px 0px"}]))

(def slider-value (solid:signal 200))

(fqn
  (resolve 'app))

(defn app []
  (solid:dom
    (if (not @webaudio:ctx)
      [:button.getting-started {:on-click (webaudio:init!)}
       "Get started!"]
      [:div
       [:p "vibes"]
       [:input {:type "range"
                :min 50
                :max 1000
                :value @slider-value
                :on-input (fn [e] (reset! slider-value (.-value (.-target e))))}]])))

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
                       (constant {:offset freq}))
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
