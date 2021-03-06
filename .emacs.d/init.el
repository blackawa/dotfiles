;;; Packages:
(when (or (require 'cask "~/.cask/cask.el" t)
          (require 'cask nil t))
  (cask-initialize))

;;; Variables:
(setq make-backup-files nil)
(setq-default indent-tabs-mode nil)
(setq cperl-invalid-face 'default)

(require 'whitespace)
(global-whitespace-mode 1)
(setq whitespace-action '(auto-cleanup))
(setq whitespace-space-regexp "\\(\u3000+\\)")
(setq whitespace-style '(face trailing tabs))

;; Set alt key as meta
(setq x-alt-keysym 'meta)

(load-theme 'monokai t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(nyan-bar-length 16)
 '(package-selected-packages
   (quote
    (elm-mode yasnippet yaml-mode web-mode use-package smartparens prodigy popwin paredit pallet nyan-mode neotree multiple-cursors markdown-mode magit idle-highlight-mode htmlize helm-smex helm-projectile haskell-mode flycheck-cask expand-region exec-path-from-shell drag-stuff darcula-theme company-go cider)))
 '(safe-local-variable-values
   (quote
    ((cider-refresh-after-fn . "integrant.repl/resume")
     (cider-refresh-before-fn . "integrant.repl/suspend")))))
(nyan-mode t)

(if (version<= "26.0.50" emacs-version)
    (display-line-numbers-mode))

;;; Use packages:
(require 'use-package)
(use-package helm
  :defer t
  :diminish helm-mode
  :bind (("C-x C-f" . helm-find-files)
         ("M-x" . helm-smex))
  :init
  (require 'helm-config)
  (helm-mode t))
(use-package paredit
  :defer t
  :init
  (add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
  (add-hook 'clojure-mode-hook 'enable-paredit-mode)
  (add-hook 'cider-repl-mode-hook 'enable-paredit-mode))
(use-package markdown-mode
  :ensure t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :init (setq markdown-command "multimarkdown"))
(use-package go-mode
  :ensure t
  :commands (go-mode)
  :init
  (add-hook 'go-mode-hook
            (lambda ()
              (add-hook 'before-save-hook 'gofmt-before-save)
              (setq c-basic-offset 4)
              (setq tab-width 4))))
(use-package projectile
  :init
  (projectile-mode t))
(use-package neotree
  :defer t
  :init
  (defun neotree-project-dir ()
    "Open NeoTree using the git root."
    (interactive)
    (let ((project-dir (projectile-project-root))
          (file-name (buffer-file-name)))
      (neotree-toggle)
      (if project-dir
          (if (neo-global--window-exists-p)
              (progn
                (neotree-dir project-dir)
                (neotree-find file-name)))
        (message "Could not find git project root.")))))
(use-package yaml-mode
  :ensure t
  :mode (("\\.ya?ml\\'" . yaml-mode)))
(use-package haskell-mode
  :ensure t
  :mode (("\\.hs$" . haskell-mode)))
(use-package elm-mode
  :ensure t
  :mode (("\\.elm$" . elm-mode)))

;;; Key config:
(define-key key-translation-map [?\C-h] [?\C-?])
(bind-key "M-'" 'other-window)

(defvar spacemaps (make-sparse-keymap) "Spacemacsを真似したkeymap")
(defalias 'spacemaps-prefix spacemaps)
(bind-key "M-SPC" 'spacemaps-prefix)

(defvar filemaps (make-sparse-keymap) "ファイル操作のkeymap")
(defalias 'filemaps-prefix filemaps)
(bind-key "f" 'filemaps-prefix spacemaps)
(bind-keys :map filemaps
           ("f" . helm-find-files)
           ("l" . load-file)
           ("r" . helm-recentf)
           ("t" . neotree-toggle))

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

(defvar projectmaps (make-sparse-keymap) "プロジェクト操作のkeymap")
(defalias 'projectmaps-prefix projectmaps)
(bind-key "p" 'projectmaps-prefix spacemaps)
(bind-keys :map projectmaps
           ("f" . helm-projectile)
           ("t" . neotree-project-dir))

(defvar gitmaps (make-sparse-keymap) "Git操作のkeymap")
(defalias 'gitmaps-prefix gitmaps)
(bind-key "g" 'gitmaps-prefix spacemaps)
(bind-keys :map gitmaps
           ("s" . magit-status))

;; custom-set-variables was added by Custom.

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
