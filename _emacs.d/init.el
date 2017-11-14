;;; Packages:
(when (or (require 'cask "~/.cask/cask.el" t)
	  (require 'cask nil t))
  (cask-initialize))
(package-initialize)

;;; Variables:
(setq make-backup-files nil)

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

(defvar spacemaps (make-sparse-keymap) "Spacemacsを真似したkeymap")
(defalias 'spacemaps-prefix spacemaps)
(bind-key "M-SPC" 'spacemaps-prefix)

(defvar filemaps (make-sparse-keymap) "ファイル操作のkeymap")
(defalias 'filemaps-prefix filemaps)
(bind-key "f" 'filemaps-prefix spacemaps)
(bind-keys :map filemaps
	   ("f" . find-file)
	   ("l" . load-file))

(defvar stringmaps (make-sparse-keymap) "文字列操作のkeymap")
(defalias 'stringmaps-prefix stringmaps)
(bind-key "s" 'stringmaps-prefix spacemaps)
(bind-keys :map stringmaps
	   ("i" . indent-region))

;; custom-set-variables was added by Custom.
(custom-set-variables
 '(safe-local-variable-values
   (quote
    ((cider-refresh-after-fn . "integrant.repl/resume")
     (cider-refresh-before-fn . "integrant.repl/suspend")))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 )
