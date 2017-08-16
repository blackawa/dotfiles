(use-package markdown-mode
             :ensure t
             :commands (markdown-mode gfm-mode)
             :mode (("readme\\.md\\'" . gfm-mode)
                    ("\\.md\\'" . markdown-mode)
                    ("\\.markdown\\'" . markdown-mode))
             :init (setq markdown-command "multimarkdown"))
