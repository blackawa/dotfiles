;; SBCLをデフォルトのCommon Lisp処理系に設定
(setq inferior-lisp-program "sbcl")
;; SLIMEのロード
(require 'slime)
(slime-setup '(slime-repl slime-fancy slime-banner))
