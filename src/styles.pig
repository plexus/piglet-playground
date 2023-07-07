(module styles
  (:import
    [styling :from styling]))

(def mono-font "'fantasque_sans_monoregular'" )

(styling:style!
  (list
    [:body {:background-color "hsl(41, 100%, 76%)"
            :font-family mono-font
            :overflow "hidden"
            :margin 0
            :user-select "none"}]

    [:pre {:margin 0
           :font-family mono-font}]

    [:#app
     {:display :flex
      :width "100vw"
      :height "100vh"
      :justify-content :center
      :align-items :center}]


    [:.ui {:width "100vw" :height "100vh"}]

    [:.handle
     {:color "hsl(200, 20%, 70%)"
      :cursor "grab"
      :font-size "130%"
      :letter-spacing "-0.145em"
      :margin-left "-0.08em"
      }]

    [:.connector
     {:line-height "1em"
      :width "1em"
      :height "1em"
      :display "inline-block"}]

    [:.wire
     {:text-align "center"}
     [:.segment {:margin-top "-10px"
                 :margin-left "-10px"


                 :width "1em"
                 :height "1em"}]]

    [:.dragging
     {:cursor "grabbing"}]

    ["input[type=range]"
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
     {:display "flex"}]

    [:.positioned
     {:position "absolute"
      :top 0 :left 0}]


    ))
