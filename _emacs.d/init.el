(require 'cask "/usr/local/Cellar/cask/0.7.4/cask.el")
(cask-initialize)
(require 'pallet)
(require 'init-loader)
(pallet-mode t)

; init-loader configurations
(setq init-loader-show-log-after-init nil)
(init-loader-load "~/.emacs.d/inits")

; add packages
(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/") t)
(package-initialize)
