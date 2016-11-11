;; (require 'anything-startup)

(require 'anything)
(require 'anything-config)
(add-to-list 'anything-sources 'anything-c-source-emacs-commands)
(global-set-key "\C-q" 'anything)
