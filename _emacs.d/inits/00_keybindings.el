;; C-h for backspace
(keyboard-translate ?\C-h ?\C-?)

;;; 分割したウィンドウを移動する
(global-set-key (kbd "C-c b")  'windmove-left)
(global-set-key (kbd "C-c f") 'windmove-right)
(global-set-key (kbd "C-c p")    'windmove-up)
(global-set-key (kbd "C-c n")  'windmove-down)
(setq windmove-wrap-around t)

;;; hs-minor-modeが有効な時、Ctrl + Backslash でコードを畳み込む
(define-key global-map (kbd "C-\\") 'hs-toggle-hiding)
