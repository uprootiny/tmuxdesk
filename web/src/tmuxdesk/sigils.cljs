(ns tmuxdesk.sigils
  "Extended sigil vocabulary — alchemical, mathematical, eastern, astrological.")

;; Alchemical (U+1F700 block)
(def alch-fire     "🜂")  ; fire
(def alch-air      "🜁")  ; air
(def alch-earth    "🜃")  ; earth
(def alch-water    "🜄")  ; water
(def alch-salt     "🜔")  ; salt of copper antimoniate
(def alch-sublim   "🜎")  ; sublimation
(def alch-amalg    "🝆")  ; caput mortuum
(def alch-crucible "🝊")  ; crucible

;; Mathematical
(def therefore     "∴")
(def because       "∵")
(def infinity      "∞")
(def nabla         "∇")
(def partial-d     "∂")
(def integral      "∫")
(def contour-int   "∮")
(def summation     "∑")
(def product       "∏")
(def aleph         "ℵ")
(def weierstrass   "℘")
(def circled-plus  "⊕")
(def circled-times "⊗")
(def circled-dot   "⊙")
(def tensor        "⊗")
(def turnstile     "⊢")
(def lambda        "λ")
(def forall        "∀")
(def exists        "∃")
(def emptyset      "∅")
(def proportional  "∝")

;; Eastern / I Ching trigrams
(def heaven        "☰")  ; qian
(def lake          "☱")  ; dui
(def trigram-fire  "☲")  ; li
(def thunder       "☳")  ; zhen
(def wind          "☴")  ; xun
(def trigram-water "☵")  ; kan
(def mountain      "☶")  ; gen
(def earth-tri     "☷")  ; kun
(def yinyang       "☯")
(def dharma        "☸")
(def om            "ॐ")

;; Astrological / Celestial
(def mercury       "☿")
(def venus         "♀")
(def mars          "♂")
(def jupiter       "♃")
(def saturn        "♄")
(def sun           "☉")
(def moon          "☽")
(def star-6        "✡")
(def star-8        "✴")

;; State indicators
(def state-active  "●")
(def state-idle    "○")
(def state-dead    "✕")
(def state-quiet   "·")

;; Decorative / structural
(def section-mark  "§")
(def pilcrow       "¶")
(def dagger        "†")
(def double-dag    "‡")
(def lozenge       "◊")
(def bullet        "•")

;; Fleet nodes with extended metadata
(def fleet
  [{:id :hyle      :sigil alch-fire  :name "hyle"      :ip "173.212.203.211"
    :role "creative fire"  :element :fire  :planet sun
    :desc "Prima materia — where all work ignites"}
   {:id :hub2      :sigil therefore  :name "hub2"      :ip "149.102.137.139"
    :role "coordination"   :element :air   :planet mercury
    :desc "Logical hub — conclusions drawn, actions dispatched"}
   {:id :finml     :sigil heaven     :name "finml"     :ip "5.189.145.105"
    :role "pattern/ML"     :element :metal :planet jupiter
    :desc "Heaven trigram — reading patterns in data"}
   {:id :karlsruhe :sigil infinity   :name "karlsruhe" :ip "45.90.121.59"
    :role "pure/NixOS"     :element :water :planet saturn
    :desc "Lemniscate — infinite reproducibility"}
   {:id :nabla     :sigil nabla      :name "nabla"     :ip "35.252.20.194"
    :role "GCP compute"    :element :earth :planet mars
    :desc "Del operator — gradient descent toward optimal"}])

;; Ambient sigils for decoration (cycle through these)
(def ambient-sigils
  [alch-fire alch-air alch-earth alch-water
   heaven lake trigram-fire thunder wind trigram-water mountain earth-tri
   therefore nabla infinity partial-d integral contour-int
   mercury venus mars jupiter saturn sun moon
   aleph weierstrass lambda om dharma yinyang])
