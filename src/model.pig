(module model
  (:import
    [solid :from solid:solid]
    [webaudio :from webaudio]))

(defmulti start! :type)

(defmethod start! :default [c]
  ((resolve (:type c)) (dissoc c :type)))

(def graph
  (solid:signal
    {}
    ))

(defn nodes []
  (for [[k v] (:nodes @graph)]
    (assoc v :id k)))

(defn node [id]
  (solid:cursor graph [:nodes id]))

(defn start-nodes [graph]
  (update graph :nodes
    (fn [nodes]
      (reduce (fn [acc [k v]]
                (assoc acc k (assoc v :object (start! v))))
        {}
        nodes))))

(defn connect-wires [graph]
  (let [node (fn [id] (get-in graph [:nodes id :object]))]
    (doseq [[from to] (:edges graph)]
      (println "connecting" from to)
      (let [[from from-idx] (if (vector? from) from [from 0])
            [to to-idx]   (if (vector? to) to [to 0])]
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
  (swap! graph
    (fn [g]
      (webaudio:assign-prop
        (get-in @graph [:nodes node-id :object])
        param value)
      (assoc-in g [:nodes node-id param] value))))

(defn set-prop! [node-id prop value]
  (swap! graph
    (fn [g]
      (assoc-in g [:nodes node-id prop] value))))

;; (swap! graph (fn [g] (-> g start-nodes connect-wires)))

;; (ctl! "master" :gain 0)
;; (ctl! "lfo" :frequency 1)
;; (ctl! "osc1" :frequency 150)
;; (ctl! "lfo-gain" :gain 135)

(comment

  (reset! graph
    {:nodes {"osc1" {:type `webaudio:osc
                     :frequency 440
                     :type "square"
                     :position [300 300]}
             "lfo" {:type `webaudio:osc
                    :frequency 10
                    :type "sine"
                    :position [300 100]}
             "lfo-gain" {:type `webaudio:gain
                         :gain 10
                         :position [300 200]}
             "master" {:type `webaudio:gain
                       :desc "Master bus"
                       :gain 0.0
                       :position [300 400]}
             "speaker" {:type `webaudio:dest
                        :position [300 500]}
             "lfo-const" {:type `webaudio:constant
                          :offset 300
                          :position [200 200]}}
     :edges [["master" "speaker"]
             ["osc1" "master"]
             ["lfo" "lfo-gain"]
             ["lfo-gain" ["osc1" :frequency]]
             ["lfo-const" ["osc1" :frequency]]
             ]})



  (do @graph)

  {:edges [["master", "speaker"], ["osc1", "master"], ["lfo", "lfo-gain"], ["lfo-gain", ["osc1", :frequency]], ["lfo-const", ["osc1", :frequency]]],
   :nodes {"osc1" {:type https://piglet-lang.org/packages/piglet-playground:webaudio:osc, :frequency 440, :type "square", :position [300, 300]}
           "lfo" {:type https://piglet-lang.org/packages/piglet-playground:webaudio:osc, :frequency 10, :type "sine", :position [300, 100]}
           "lfo-gain" {:type https://piglet-lang.org/packages/piglet-playground:webaudio:gain, :gain 10, :position [300, 200]}
           "master" {:type https://piglet-lang.org/packages/piglet-playground:webaudio:gain, :desc "Master bus", :gain 0, :position [300, 400]}
           "speaker" {:type https://piglet-lang.org/packages/piglet-playground:webaudio:dest, :position [300, 500]}
           "lfo-const" {:type https://piglet-lang.org/packages/piglet-playground:webaudio:constant, :offset 300, :position [200, 200]}
           :edges {:position [0, 0]}
           :nodes {:position [0, 0]}}}
  )
