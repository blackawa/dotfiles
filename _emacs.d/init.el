;;; Packages:
(when (or (require 'cask "~/.cask/cask.el" t)
          (require 'cask nil t))
  (cask-initialize))
(package-initialize)

;;; Variables:
(setq make-backup-files nil)
(setq-default indent-tabs-mode nil)
(setq cperl-invalid-face 'default)

(require 'whitespace)
(global-whitespace-mode 1)
(setq whitespace-action '(auto-cleanup))
(setq whitespace-space-regexp "\\(\u3000+\\)")
(setq whitespace-style '(face trailing tabs))

(load-theme 'darcula t)

;;; Use packages:
(require 'use-package)
(use-package helm
  :defer t
  :diminish helm-mode
  :init
  (require 'helm-config)
  (bind-key "C-x C-f" 'helm-find-files)
  (bind-key "M-x" 'helm-smex)
  (helm-mode t))
(use-package paredit
  :defer t
  :init
  (add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode))
(use-package markdown-mode
  :ensure t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :init
  (setq markdown-command "multimarkdown"))

;;; Key config:
(bind-key "C-h" 'delete-backward-char)
(bind-key "M-'" 'next-multiframe-window)

(defvar spacemaps (make-sparse-keymap) "Spacemacsを真似したkeymap")
(defalias 'spacemaps-prefix spacemaps)
(bind-key "M-SPC" 'spacemaps-prefix)

(defvar filemaps (make-sparse-keymap) "ファイル操作のkeymap")
(defalias 'filemaps-prefix filemaps)
(bind-key "f" 'filemaps-prefix spacemaps)
(bind-keys :map filemaps
           ("f" . helm-find-files)
           ("l" . load-file))

(defvar stringmaps (make-sparse-keymap) "文字列操作のkeymap")
(defalias 'stringmaps-prefix stringmaps)
(bind-key "s" 'stringmaps-prefix spacemaps)
(bind-keys :map stringmaps
           ("i" . indent-region))

(defvar windowmaps (make-sparse-keymap) "ウィンドウ操作のkeymap")
(defalias 'windowmaps-prefix windowmaps)
(bind-key "w" 'windowmaps-prefix spacemaps)
(bind-keys :map windowmaps
           ("-" . split-window-below)
           ("/" . split-window-right)
           ("p" . windmove-up)
           ("n" . windmove-down)
           ("f" . windmove-right)
           ("b" . windmove-left))

;; custom-set-variables was added by Custom.
(custom-set-variables
 '(safe-local-variable-values
   (quote
    ((cider-refresh-after-fn . "integrant.repl/resume")
     (cider-refresh-before-fn . "integrant.repl/suspend")))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 )
