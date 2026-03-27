(ns tmuxdesk.core
  (:require [reagent.core :as r]
            [reagent.dom.client :as rdc]
            [tmuxdesk.essays :as essays]
            [tmuxdesk.sigils :as sig]))

;; --- State ---
(defonce app-state (r/atom {:view :index
                            :scroll-pct 0
                            :tick 0
                            :fleet-state (into {}
                                           (map (fn [{:keys [id]}]
                                                  [id {:sessions (+ 1 (rand-int 4))
                                                       :attached (rand-nth [true true true false])
                                                       :load (+ 0.1 (* 2.0 (rand)))}])
                                                sig/fleet))}))

(defonce root (atom nil))
(defonce tick-timer (atom nil))

;; --- Tick for ambient animations ---
(defn tick! []
  (swap! app-state update :tick inc)
  ;; Simulate fleet state drift
  (when (zero? (mod (:tick @app-state) 12))
    (swap! app-state update :fleet-state
           (fn [fs]
             (into {}
               (map (fn [[k v]]
                      [k (-> v
                             (assoc :sessions (max 0 (+ (:sessions v) (rand-nth [-1 0 0 0 1]))))
                             (assoc :load (max 0.0 (min 8.0 (+ (:load v) (rand-nth [-0.3 -0.1 0 0.1 0.3])))))
                             (update :attached #(if (< (rand) 0.15) (not %) %)))])
                    fs))))))

;; --- Navigation ---
(defn navigate! [view]
  (reset! app-state (merge @app-state {:view view :scroll-pct 0}))
  (.scrollTo js/window 0 0))

;; --- Scroll tracking ---
(defn on-scroll []
  (let [doc-h (- (.. js/document -documentElement -scrollHeight)
                 (.. js/window -innerHeight))
        pct (if (pos? doc-h)
              (* 100 (/ (.. js/window -scrollY) doc-h))
              0)]
    (swap! app-state assoc :scroll-pct pct)))

;; --- Content renderers ---
(declare render-body-node)

(defn sigil-link [target-id label]
  [:span.sigil-link {:on-click #(navigate! target-id)}
   label])

(defn render-body-node [node]
  (cond
    (string? node) node

    (vector? node)
    (let [[tag & children] node]
      (case tag
        :p       (into [:p] (map render-body-node children))
        :em      (into [:em] (map render-body-node children))
        :strong  (into [:strong] (map render-body-node children))
        :code    (into [:code] (map render-body-node children))
        :kbd     (into [:kbd] (map render-body-node children))
        :ol      (into [:ol] (map render-body-node children))
        :li      (into [:li] (map render-body-node children))
        :sigil-link (let [[target-id label] children]
                      [sigil-link target-id label])
        ;; fallback
        (into [:span] (map render-body-node children))))

    :else (str node)))

;; --- Fleet Status Panel ---
(defn fleet-status-bar []
  (let [tick (:tick @app-state)
        fs (:fleet-state @app-state)]
    [:div.fleet-status-bar
     [:div.status-bar-label
      [:span.status-bar-sigil "⊙"]
      " fleet status"]
     [:div.status-bar-nodes
      (for [{:keys [id sigil name]} sig/fleet]
        (let [{:keys [sessions attached load]} (get fs id)
              state-char (cond
                           (and attached (pos? sessions)) sig/state-active
                           (pos? sessions) sig/state-idle
                           :else sig/state-quiet)]
          ^{:key id}
          [:div.status-node
           {:class (str "state-" (clojure.core/name
                                   (cond attached :active
                                         (pos? sessions) :idle
                                         :else :quiet)))
            :on-click #(navigate! :fleet)}
           [:span.status-node-sigil
            {:class (when (and attached (zero? (mod (+ tick (.indexOf (mapv :id sig/fleet) id)) 3)))
                      "pulse")}
            sigil]
           [:span.status-node-state state-char]
           [:span.status-node-count sessions]
           [:div.status-node-tooltip
            [:div.tooltip-name name]
            [:div.tooltip-load (str "λ " (.toFixed load 2))]
            [:div.tooltip-sessions (str sessions " sessions")]]]))]
     ;; Mini status line preview
     [:div.status-bar-preview
      (for [{:keys [id sigil]} sig/fleet]
        (let [{:keys [sessions attached]} (get fs id)
              sc (cond
                   (and attached (pos? sessions)) sig/state-active
                   (pos? sessions) sig/state-idle
                   :else sig/state-quiet)]
          ^{:key (str "preview-" (clojure.core/name id))}
          [:span {:class (str "preview-sigil"
                              (when attached " preview-active"))}
           (str sigil sc sessions)]))]]))

;; --- SVG Constellation ---
(defn constellation-svg []
  (let [tick (:tick @app-state)
        fs (:fleet-state @app-state)
        ;; Node positions (centered in 400x300 viewbox)
        nodes [{:id :hyle      :x 200 :y 40}
               {:id :hub2      :x 60  :y 140}
               {:id :finml     :x 200 :y 140}
               {:id :karlsruhe :x 340 :y 140}
               {:id :nabla     :x 200 :y 240}]
        ;; All edges (full mesh)
        edges (for [a nodes b nodes
                    :when (< (compare (name (:id a)) (name (:id b))) 0)]
                [a b])
        node-map (into {} (map (fn [n] [(:id n) n]) nodes))
        fleet-map (into {} (map (fn [n] [(:id n) n]) sig/fleet))]
    [:svg.constellation
     {:viewBox "0 0 400 300"
      :xmlns "http://www.w3.org/2000/svg"}
     ;; Defs for glow filters
     [:defs
      [:filter {:id "sigil-glow" :x "-50%" :y "-50%" :width "200%" :height "200%"}
       [:feGaussianBlur {:in "SourceGraphic" :stdDeviation "3" :result "blur"}]
       [:feMerge
        [:feMergeNode {:in "blur"}]
        [:feMergeNode {:in "SourceGraphic"}]]]
      [:radialGradient {:id "node-bg" :cx "50%" :cy "50%" :r "50%"}
       [:stop {:offset "0%" :stop-color "rgba(136,136,204,0.15)"}]
       [:stop {:offset "100%" :stop-color "rgba(136,136,204,0)"}]]]
     ;; Edges
     (for [[a b] edges]
       (let [ida (:id a) idb (:id b)
             sa (get fs ida) sb (get fs idb)
             active? (and (:attached sa) (:attached sb))
             opacity (if active? 0.35 0.1)]
         ^{:key (str (name ida) "-" (name idb))}
         [:line {:x1 (:x a) :y1 (:y a)
                 :x2 (:x b) :y2 (:y b)
                 :stroke (if active? "#5588cc" "#404060")
                 :stroke-width (if active? 1.5 0.7)
                 :stroke-opacity opacity
                 :stroke-dasharray (when-not active? "4 4")}]))
     ;; Nodes
     (for [{:keys [id x y]} nodes]
       (let [fleet-node (get fleet-map id)
             state (get fs id)
             attached? (:attached state)
             glow-phase (mod (+ tick (.indexOf (mapv :id sig/fleet) id)) 6)]
         ^{:key (name id)}
         [:g {:class "constellation-node"
              :style {:cursor "pointer"}
              :on-click #(navigate! :fleet)}
          ;; Ambient glow
          [:circle {:cx x :cy y :r (+ 18 (if (and attached? (< glow-phase 3)) 3 0))
                    :fill "url(#node-bg)"
                    :class (when attached? "node-glow-anim")}]
          ;; Sigil text
          [:text {:x x :y (+ y 1)
                  :text-anchor "middle"
                  :dominant-baseline "central"
                  :font-size "18"
                  :fill (if attached? "#8888cc" "#505068")
                  :filter "url(#sigil-glow)"
                  :class (when attached? "sigil-pulse")}
           (:sigil fleet-node)]
          ;; Name label
          [:text {:x x :y (+ y 24)
                  :text-anchor "middle"
                  :font-size "8"
                  :font-family "JetBrains Mono, monospace"
                  :fill "#505068"
                  :letter-spacing "0.1em"}
           (:name fleet-node)]
          ;; State dot
          [:text {:x (+ x 16) :y (- y 10)
                  :font-size "8"
                  :fill (cond attached? "#44aa88"
                              (pos? (:sessions state)) "#aa8844"
                              :else "#404060")}
           (str (cond attached? sig/state-active
                      (pos? (:sessions state)) sig/state-idle
                      :else sig/state-quiet)
                (:sessions state))]]))]))

;; --- Ambient Sigil Rain (decorative) ---
(defn ambient-sigils []
  (let [tick (:tick @app-state)]
    [:div.ambient-sigils
     (for [i (range 12)]
       (let [s (nth sig/ambient-sigils (mod (+ i tick) (count sig/ambient-sigils)))
             x-pct (+ 5 (* 8 i))
             opacity (+ 0.02 (* 0.04 (Math/sin (/ (+ tick (* i 17)) 8))))]
         ^{:key (str "amb-" i)}
         [:span.ambient-glyph
          {:style {:left (str x-pct "%")
                   :opacity opacity
                   :animation-delay (str (* i 0.3) "s")}}
          s]))]))

;; --- Components ---
(defn scroll-progress []
  [:div.scroll-progress {:style {:width (str (:scroll-pct @app-state) "%")}}])

(defn sigil-nav []
  (let [current (:view @app-state)]
    [:nav.sigil-nav
     ;; Index link
     [:div.sigil-nav-item
      {:class (when (= current :index) "active")
       :on-click #(navigate! :index)}
      [:span.sigil-nav-glyph sig/yinyang]
      [:span.sigil-nav-label "index"]]
     ;; Essay links
     (for [{:keys [id sigil title]} essays/essays]
       ^{:key id}
       [:div.sigil-nav-item
        {:class (when (= current id) "active")
         :on-click #(navigate! id)}
        [:span.sigil-nav-glyph sigil]
        [:span.sigil-nav-label title]])]))

(defn node-card [{:keys [id sigil name role]} on-click]
  (let [state (get (:fleet-state @app-state) id)
        attached? (:attached state)]
    [:div.node-card
     {:on-click on-click
      :class (when attached? "node-active")}
     [:div.node-sigil {:class (when attached? "pulse")} sigil]
     [:div.node-state-dot
      (if attached? sig/state-active sig/state-idle)
      (:sessions state)]
     [:div.node-name name]
     [:div.node-role role]]))

(defn node-grid []
  [:div.node-grid
   (for [{:keys [id] :as node} sig/fleet]
     ^{:key id}
     [node-card node #(navigate! :fleet)])])

(defn essay-panel [{:keys [sigil title subtitle body]}]
  [:article.essay-panel
   [:header.essay-header
    [:span.essay-sigil sigil]
    [:div
     [:h2.essay-title title]
     (when subtitle
       [:div {:style {:font-style "italic"
                      :color "#707088"
                      :font-size "0.88rem"
                      :margin-top "0.2rem"}}
        subtitle])]]
   (into [:div.essay-body]
         (map render-body-node body))])

(defn index-view []
  [:div
   [ambient-sigils]
   [:div.codex-header
    [:h1.codex-title [:span.sigil sig/alch-fire] " tmuxdesk codex"]
    [:p.codex-subtitle "distributed terminal infrastructure"]
    [:div.codex-sigil-row
     (for [{:keys [sigil]} sig/fleet]
       ^{:key sigil}
       [:span.header-fleet-sigil sigil])]]
   [fleet-status-bar]
   [sigil-nav]
   [node-grid]
   [:div.section-break (str sig/alch-air " " sig/yinyang " " sig/alch-water)]
   [constellation-svg]
   [:div.section-break (str sig/thunder " " sig/dharma " " sig/wind)]
   [:div
    (for [{:keys [id sigil title subtitle]} essays/essays]
      ^{:key id}
      [:div.essay-index-item {:on-click #(navigate! id)}
       [:span.idx-sigil sigil]
       [:div
        [:div.idx-title title]
        [:div.idx-subtitle subtitle]]])]])

(defn essay-view [essay-id]
  (let [essay (get essays/essay-index essay-id)]
    (if essay
      [:div
       [sigil-nav]
       [essay-panel essay]
       ;; Prev/next navigation
       (let [ids (mapv :id essays/essays)
             idx (.indexOf ids essay-id)
             prev-id (when (pos? idx) (nth ids (dec idx)))
             next-id (when (< idx (dec (count ids))) (nth ids (inc idx)))]
         [:div.essay-nav-row
          (if prev-id
            (let [prev-essay (get essays/essay-index prev-id)]
              [:span.sigil-link {:on-click #(navigate! prev-id)}
               (str "← " (:sigil prev-essay) " " (:title prev-essay))])
            [:span])
          (if next-id
            (let [next-essay (get essays/essay-index next-id)]
              [:span.sigil-link {:on-click #(navigate! next-id)}
               (str (:sigil next-essay) " " (:title next-essay) " →")])
            [:span])])]
      [:div
       [sigil-nav]
       [:div.essay-panel
        [:p "Essay not found. "
         [:span.sigil-link {:on-click #(navigate! :index)} "Return to index."]]]])))

(defn codex-footer []
  [:footer.codex-footer
   [:div.footer-sigil-row
    (for [s [sig/alch-fire sig/therefore sig/heaven sig/infinity sig/nabla]]
      ^{:key s} [:span.footer-glyph s])]
   [:p "tmuxdesk " sig/bullet " distributed terminal infrastructure"]
   [:p {:style {:margin-top "0.4rem"}}
    "built in ClojureScript " sig/bullet " "
    [:span.sigil-link {:on-click #(navigate! :index)} "return to index"]]])

;; --- App root ---
(defn app []
  (let [{:keys [view]} @app-state]
    [:div.codex
     [scroll-progress]
     (if (= view :index)
       [index-view]
       [essay-view view])
     [codex-footer]]))

;; --- Mount ---
(defn ^:dev/after-load reload! []
  (when-let [r @root]
    (.render r (r/as-element [app]))))

(defn init! []
  (.addEventListener js/window "scroll" on-scroll)
  ;; Start ambient tick
  (when-let [t @tick-timer] (js/clearInterval t))
  (reset! tick-timer (js/setInterval tick! 2000))
  (let [r (rdc/create-root (.getElementById js/document "app"))]
    (reset! root r)
    (.render r (r/as-element [app]))))
