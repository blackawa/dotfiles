---
name: testing-browser
description: |
  agent-browser CLI を使ったブラウザテスト・動作確認時に適用する規約とベストプラクティス。
  「ブラウザで確認」「画面テスト」「フォーム動作確認」「ビジュアル確認」「E2Eテスト」
  「ページを開いて」「画面を見て」「スクリーンショットを撮って」「UIの確認」
  「ブラウザで動作検証」「画面の差分を確認」「レスポンシブ確認」
  といった発言があれば、このスキルを使うこと。
  フロントエンド実装後の動作検証、フォーム送信テスト、ナビゲーション確認にも適用される。
---

# Browser Testing with agent-browser CLI

agent-browser（Vercel Labs 製）を使い、AI エージェントとしてブラウザを自動操作する。
コマンド詳細は `agent-browser --help` で確認すること。

---

## 1. セットアップ

```bash
npm install -g agent-browser
agent-browser install  # 初回のみ: Chromium をダウンロード
```

---

## 2. 基本ワークフロー: Snapshot + Refs パターン

すべてのブラウザ操作は以下のサイクルで行う。**例外なくこの順序を守る。**

```
open → snapshot -i → 操作(click/fill) → wait → snapshot -i → ... → close
```

```bash
agent-browser open http://localhost:3000/login

agent-browser snapshot -i
# 出力例:
#   @e1: <input type="email" placeholder="Email">
#   @e2: <input type="password" placeholder="Password">
#   @e3: <button>ログイン</button>

agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3

# 操作後に wait → 再 snapshot（ref が変わる）
agent-browser wait --load networkidle
agent-browser snapshot -i

agent-browser close
```

### 絶対に守るルール

1. **操作前に必ず `snapshot -i`** — ref は snapshot 取得時に割り当てられる。推測禁止
2. **操作後に必ず再 `snapshot -i`** — ページ遷移・DOM 変更で ref は無効化される
3. **`-i` フラグを使う** — フルスナップショットはトークンを浪費する
4. **`wait` を挟む** — 遷移・非同期処理の後は `wait --load networkidle`
5. **必ず `close` する** — プロセスが残り次回の操作に影響する

---

## 3. よく使うコマンド

```bash
# ナビゲーション
agent-browser open <url>
agent-browser close
agent-browser wait --load networkidle

# スナップショット・確認
agent-browser snapshot -i          # インタラクティブ要素（ref付き）
agent-browser snapshot             # ページ全体
agent-browser screenshot /tmp/out.png
agent-browser get url
agent-browser get title

# 操作（ref は snapshot -i の出力に基づく）
agent-browser click @e1
agent-browser fill @e2 "text"
agent-browser select @e3 "value"
agent-browser check @e4
agent-browser press Enter
agent-browser hover @e5
agent-browser scroll down

# ref が不明な場合のセマンティック検索
agent-browser find text "ログイン"
agent-browser find role "button"
agent-browser find label "メールアドレス"
agent-browser find testid "submit-btn"

# レスポンシブ・デバイス
agent-browser set viewport 375 812
agent-browser set device "iPhone 15"

# 差分・デバッグ
agent-browser diff snapshot        # 前回との差分
agent-browser diff screenshot      # ビジュアル差分
agent-browser console              # コンソールログ
agent-browser error                # エラーログ
agent-browser set offline true     # オフライン切替
```

---

## 4. テストシナリオ

### フォーム送信

```bash
agent-browser open http://localhost:3000/contact
agent-browser snapshot -i
agent-browser fill @e1 "山田太郎"
agent-browser fill @e2 "yamada@example.com"
agent-browser click @e3  # 送信ボタン
agent-browser wait --load networkidle
agent-browser snapshot
agent-browser screenshot /tmp/form-submitted.png
agent-browser close
```

### レスポンシブ確認

```bash
agent-browser open http://localhost:3000
agent-browser set viewport 375 812 && agent-browser screenshot /tmp/mobile.png
agent-browser set viewport 768 1024 && agent-browser screenshot /tmp/tablet.png
agent-browser set viewport 1440 900 && agent-browser screenshot /tmp/desktop.png
agent-browser close
```

### デバッグ

```bash
agent-browser snapshot
agent-browser console
agent-browser error
agent-browser screenshot /tmp/error-state.png
```

---

## 5. アンチパターン

| ❌ やってはいけない | ✅ 代わりにやること |
|---|---|
| snapshot なしで ref を推測 | 操作前に必ず `snapshot -i` |
| 古い ref を使い回す | ページ変更後は再度 `snapshot -i` |
| `snapshot`（フル）を毎回使う | `snapshot -i` で十分 |
| `wait` なしで遷移後すぐ操作 | `wait --load networkidle` を挟む |
| ブラウザを閉じ忘れる | 操作完了後は必ず `close` |
| CSS セレクタや XPath で指定 | ref または `find` コマンドを使用 |
| 認証情報をハードコード | 環境変数やテスト fixture を使う |

---

## 6. チェックリスト

- [ ] `agent-browser install` 済み / サーバー起動済み / 前回セッション `close` 済み
- [ ] 操作前に `snapshot -i` で ref 取得 / 操作後に再 `snapshot -i`
- [ ] `wait --load networkidle` で非同期処理の完了を待機
- [ ] スクリーンショットを保存 / ブラウザを `close`
