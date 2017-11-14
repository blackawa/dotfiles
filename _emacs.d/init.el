;;; Packages:
(when (or (require 'cask "~/.cask/cask.el" t)
	  (require 'cask nil t))
  (cask-initialize))
(package-initialize)

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

;;; Key config
(progn
  (bind-key "C-h" 'delete-backward-char))
