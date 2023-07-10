(module components
  (:import
    [solid :from solid:solid]
    [webaudio :from webaudio]
    [draggable :from draggable]
    [model :from model]
    [geom :from dom-geom]
    ))

(defmulti render-component :type)

(defmethod render-component :default [compo]
  (println "COMPO" compo)
  (solid:dom
    [:pre
     [:div
      [:p ":id=" (:id compo)]
      (for [[k v] (dissoc compo :id)]
        [:p (str k) "=" (str v)])]]))

(defn render [id]
  (println "RENDERID" id)
  (let [node (model:node id)]
    (println "COMPO2" @node)
    (solid:dom
      [draggable:draggable
       {:init-pos (geom:point (:position @node))
        :on-position-changed (fn [e]
                               (let [bounds (draggable:bounding-rect (.-target e))]
                                 (println [(:x bounds) (:y bounds)])
                                 (model:set-prop! id :position
                                   [(:x bounds) (:y bounds)])))}
       (render-component @node)])))
