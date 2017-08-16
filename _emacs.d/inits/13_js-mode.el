(require 'typescript-mode)
(require 'tide)
(require 'js2-mode)
(require 'company)

(autoload 'js2-mode "js2-mode" nil t)
(add-hook 'after-init-hook #'global-flycheck-mode)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.ejs\\'" . web-mode))

(add-hook 'js2-mode-hook
          (lambda () (tern-mode t)))

(eval-after-load 'tern-mode
  '(progn (require 'tern-auto-complete)
          (tern-ac-setup)))

;;; TypeScriptの設定
(add-hook 'typescript-mode-hook
          (lambda ()
            (tide-setup)
            (flycheck-mode t)
            (setq flycheck-check-syntax-automatically '(save mode-enabled))
            (eldoc-mode t)
            (company-mode-on)))
;;; C-n, C-pで補完候補を選べるように
(define-key company-active-map (kbd "M-n") nil)
(define-key company-active-map (kbd "M-p") nil)
(define-key company-active-map (kbd "C-n") 'company-select-next)
(define-key company-active-map (kbd "C-p") 'company-select-previous)
;;; C-hがデフォルトでドキュメント表示にmapされているので、文字を消せるようにmapを外す
(define-key company-active-map (kbd "C-h") nil)
;;; 1つしか候補がなかったらtabで補完、複数候補があればtabで次の候補へ行くように
(define-key company-active-map (kbd "<tab>") 'company-complete-common-or-cycle)
;;; ドキュメント表示
(define-key company-active-map (kbd "M-d") 'company-show-doc-buffer)

(setq company-minimum-prefix-length 1) ;; 1文字入力で補完されるように
 ;;; 候補の一番上でselect-previousしたら一番下に、一番下でselect-nextしたら一番上に行くように
(setq company-selection-wrap-around t)

;; jsxの設定
(add-to-list 'auto-mode-alist '("\\.jsx\\'" . js2-jsx-mode))
(flycheck-add-mode 'javascript-eslint 'js2-jsx-mode)
(add-hook 'js2-jsx-mode-hook 'flycheck-mode)
