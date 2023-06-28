(module webaudio
  (:import [solid :from solid:solid]))

(def ctx (solid:signal nil))

(defn init! []
  (reset! ctx (js:AudioContext.)))

(defn now [] (.-currentTime @ctx))
(defn dest [] (.-destination @ctx))

(defn plug [from to]
  (.connect from to))

(defn unplug [from to]
  (.disconnect from to))

(defn node? [n]
  (instance? js:AudioNode n))

(defn param? [n]
  (instance? js:AudioParam n))

(defn assign-prop [o k v]
  (let [prop (oget o k)]
    (cond
      (= :in k)
      (plug v o)

      (satisfies? solid:Signal v)
      (solid:effect
        (assign-prop o k @v))

      (param? prop)
      (if (node? v)
        (plug v prop)
        (.setValueAtTime prop v (now)))

      :else
      (if (and (node? v) (node? prop))
        (plug v prop)
        (oset o k v)))))

(defn assign-props [o props]
  (doseq [[k v] props]
    (assign-prop o k v))
  o)

(defn osc [opts]
  (doto
    (assign-props (.createOscillator @ctx) opts)
    (.start)))

(defn gain [opts]
  (assign-props (.createGain @ctx) opts))

(defn constant [opts]
  (doto
    (assign-props (.createConstantSource @ctx) opts)
    (.start)))

(defn merger [count]
  (.createChannelMerger @ctx count))

(defn mix [& ins]
  (let [merger (merger (count ins))]
    (doseq [[in idx] (map list ins (range))]
      (.connect in merger 0 idx))
    merger))
