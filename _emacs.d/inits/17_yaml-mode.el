(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\\.ya?ml$" . yaml-mode))
(add-to-list 'auto-mode-alist '("\\.reek$" . yaml-mode))
(define-key yaml-mode-map "\C-m" 'newline-and-indent)
