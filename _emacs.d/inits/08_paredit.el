; カッコの対応関係を整理する
(require 'paredit)
(add-hook 'clojure-mode-hook 'paredit-mode)

; カッコのハイライト
(show-paren-mode t) ; 対応するカッコのハイライト
(setq show-paren-style 'mixed) ; カッコのハイライト設定
