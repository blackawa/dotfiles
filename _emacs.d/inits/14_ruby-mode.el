(require 'ruby-electric)
(add-hook 'ruby-mode-hook '(lambda () (ruby-electric-mode t)))
(setq ruby-electric-expand-delimiters-list nil)
(setq ruby-insert-encoding-magic-comment nil) ;; coding: utf-8というコメントを挿入させない

(require 'ruby-block)
(ruby-block-mode t)
(setq ruby-block-highlight-toggle t)

(add-hook 'ruby-mode-hook
          '(lambda()
             (hs-minor-mode 1)))

;; コードの折りたたみ
(let ((ruby-mode-hs-info
        '(ruby-mode
           "class\\|module\\|def\\|if\\|unless\\|case\\|while\\|until\\|for\\|begin\\|do"
           "end"
           "#"
           ruby-move-to-block
           nil)))
  (if (not (member ruby-mode-hs-info hs-special-modes-alist))
    (setq hs-special-modes-alist
          (cons ruby-mode-hs-info hs-special-modes-alist))))

;; slim
(add-to-list 'auto-mode-alist '("\\.slim?\\'" . slim-mode))
