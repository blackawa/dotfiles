(setq next-line-add-newlines nil)
(setq-default tab-width 4 indent-tabs-mode nil)

;; バックアップファイルを作らない
(setq make-backup-files nil)
(setq auto-save-default nil)

;; ファイル名の補完でcaseを無視する
(setq completion-ignore-case t)

;; 他エディタでファイルが編集されたら自動で再読み込み
(global-auto-revert-mode 1)

;; 必ず行番号を表示する
(global-linum-mode t)

;; スクロールを一行ずつにする
(setq scroll-step 1)

;; 保存するたびに行末の空白を削除する
(add-hook 'before-save-hook 'delete-trailing-whitespace)
