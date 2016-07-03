(use-package clojure-mode
  :init
  (add-hook 'clojure-mode-hook #'yas-minor-mode)
  (add-hook 'clojure-mode-hook #'subword-mode))
;; letなどを自動で整形してくれる
(clojure-align-forms-automatically)
