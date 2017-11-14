;;; Packages:
(when (or (require 'cask "~/.cask/cask.el" t)
	  (require 'cask nil t))
  (cask-initialize))
(package-initialize)

;;; Variables:
(setq make-backup-files nil)

;;; Use packages:
(require 'use-package)
(use-package helm :defer t
  :diminish helm-mode
  :init
  (require 'helm-config)
  (bind-key "C-x C-f" 'helm-find-files)
  (bind-key "M-x" 'helm-smex)
  (helm-mode t))
(use-package paredit :defer t
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
(progn
  (bind-key "C-h" 'delete-backward-char))

;; custom-set-variables was added by Custom.
(custom-set-variables
 '(safe-local-variable-values
   (quote
    ((cider-refresh-after-fn . "integrant.repl/resume")
     (cider-refresh-before-fn . "integrant.repl/suspend")))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 )
