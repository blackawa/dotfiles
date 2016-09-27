(use-package cider)

(add-hook 'clojure-mode-hook
          '(lambda () (hs-minor-mode 1)))
