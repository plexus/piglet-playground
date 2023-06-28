(module dev-server
  (:import
    [http :from piglet:node/http-server]
   ))

(keys http)
(:create-server http)

(def piglet-lang-path
  (path:resolve
    (url:fileURLToPath
      (.-location (find-package 'piglet)))
    "../.."))

(def roots [(path:resolve (process:cwd) "./public")])

(def package-locations
  (reference
    {"self" (process:cwd)
     "piglet" piglet-lang-path}))

(def ext->mime
  (into {"pig" ["application/piglet" true "UTF-8"]}
    (for [[mime opts] (->pig mime-db:default)
          :when (:extensions opts)
          ext (:extensions opts)
          :let [comp (:compressible opts)
                charset (:charset opts)]]
      [ext [(name mime) comp charset]])))

(defn find-resource [path]
  (let [resource (some (fn [root]
                         (let [resource (path:resolve root (str "." path))]
                           (when (fs:existsSync resource)
                             resource)))
                   roots)]
    (if (and resource (.isDirectory (fs:lstatSync resource)))
      (let [index (str resource "/index.html")]
        (when (fs:existsSync index)
          index))
      resource)))

(defn media-type [filename]
  (let [[type _ charset] (or (get ext->mime (last (split "." filename)))
                           [])]

    (cond
      charset
      (str type ";charset=" charset)
      type
      type
      :else
      "application/octet-stream")))

(defn file-response [file]
  {:status 200
   :headers {"Content-Type" (media-type file)}
   :body (fs:readFileSync file)})

(def four-oh-four
  {:status 404
   :body ""})

(defn ^:async package-pig-response [url-path pkg-loc pkg-pig-loc]
  (let [pkg-pig (-> pkg-pig-loc
                  slurp
                  await
                  read-string
                  expand-qnames)]
    {:status 200
     :headers {"Content-Type" "application/piglet?charset=UTF-8"}
     :body
     (print-str
       (update pkg-pig :pkg:deps
         (fn [deps]
           (into {}
             (map (fn [[alias spec]]
                    [alias (update spec :pkg:location
                             (fn [loc]
                               (let [new-pkg-path (str (gensym "pkg"))]
                                 (swap! package-locations assoc new-pkg-path
                                   (path:resolve pkg-loc loc))
                                 (str "/" new-pkg-path))))])
               deps)))))}))

(defn handler [req]
  (if-let [file (find-resource (:path req))]
    (file-response file)
    (let [parts (split "/" (:path req))
          [_ pkg-path] parts
          ;; FIXME: [... & more] not yet working inside let
          more (rest (rest parts))
          pkg-loc (get @package-locations pkg-path)]
      (let [file (and pkg-loc (str pkg-loc "/" (join "/" more)))]
        (if (fs:existsSync file)
          (if (= ["package.pig"] more)
            (package-pig-response pkg-path pkg-loc file)
            (file-response file))
          four-oh-four)))))

(defn json-body-mw [handler]
  (fn ^:async h [req]
    (let [res (await (handler req))]
      (if (= :json (:content-type res))
        (-> res
          (assoc-in [:headers "Content-Type"] "application/json")
          (update :body (comp js:JSON.stringify ->js)))
        res))))

(def server (-> (fn [req] (handler req))
              json-body-mw
              (http:create-server {:port 1234})))


(println "Starting http server")
(http:start! server)
#_ (http:stop! server)
