(module model
  (:import
    [solid :from solid:solid]
    [webaudio :from webaudio]))

(def graph
  (solid:signal
    {:nodes {"osc1" {:type webaudio:osc
                     :frequency 440
                     :type "square"}
             "lfo" {:type webaudio:osc
                    :frequency 10
                    :type "sine"}
             "lfo-gain" {:type webaudio:gain
                         :gain 10}
             "master" {:type webaudio:gain
                       :desc "Master bus"
                       :gain 0.0}
             "speaker" {:type webaudio:dest}
             "lfo-const" {:type webaudio:constant
                          :offset 300}}
     :edges [["master" "speaker"]
             ["osc1" "master"]
             ["lfo" "lfo-gain"]
             ["lfo-gain" ["osc1" :frequency]]
             ["lfo-const" ["osc1" :frequency]]
             ]}))

(defn start-nodes [graph]
  (update graph :nodes
    (fn [nodes]
      (reduce (fn [acc [k v]]
                (assoc acc k (assoc v :object ((:type v) (dissoc v :type))))
                )
        {}
        nodes))))

(defn connect-wires [graph]
  (let [node (fn [id] (get-in graph [:nodes id :object]))]
    (doseq [[from to] (:edges graph)]
      (println "connecting" from to)
      (let [[from from-idx] (if (vector? from) from [from 0])
            [to to-idx]   (if (vector? to) to [to 0])]
        (println "connecting" from from-idx to to-idx)
        (if (keyword? to-idx)
          (do
            (println 'webaudio:connect
              (webaudio:node? (node from))
              (node from)
              (webaudio:param? (oget (node to) to-idx))
              (oget (node to) to-idx) from-idx)
            (.connect (node from) (oget (node to) to-idx) from-idx))
          (webaudio:connect (node from) (node to) from-idx to-idx))))
    graph))

(defn ctl! [node-id param value]
  (webaudio:assign-prop
    (get-in @graph [:nodes node-id :object])
    param value))

(swap! graph (fn [g] (-> g start-nodes connect-wires)))

(ctl! "master" :gain 0)
(ctl! "lfo" :frequency 3)
(ctl! "lfo-gain" :gain 135)
