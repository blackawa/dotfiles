---
name: setup-clasp-project
description: >
  clasp (Google Apps Script CLI) プロジェクトのセットアップ手順。
  フォルダ限定認証、gws CLI 連携、clasp run による自己検証ループの構築まで。
  新規GASプロジェクトを開始するとき、または既存プロジェクトを別マシンでセットアップするときに使う。
---

# clasp プロジェクト セットアップ

GAS (Google Apps Script) を clasp + gws CLI でローカル開発するための環境構築手順。

## 前提ツール

| ツール | 用途 | インストール |
|--------|------|-------------|
| clasp | GAS コードの push/pull/run | `npm i -g @google/clasp` |
| gws | Google Workspace API の CLI 操作 | `npm i -g @anthropic/gws` |
| direnv | フォルダ限定の環境変数管理 | `brew install direnv` |

## Step 1: フォルダ限定認証の設定

`.envrc` を作成し、認証情報をこのフォルダに閉じ込める。
フォルダの外では別アカウント（個人アカウント等）が使われる。

```bash
# .envrc
export CLOUDSDK_CORE_PROJECT=<GCPプロジェクトID>
export CLOUDSDK_CORE_ACCOUNT=<開発用Googleアカウント>
export clasp_config_auth="$PWD/.clasprc.json"
export GOOGLE_WORKSPACE_CLI_CONFIG_DIR="$PWD/.gws"
```

```bash
direnv allow
```

`.gitignore` に認証ファイルを追加:
```
.clasprc.json
.gws/
```

### 仕組み

| 環境変数 | 効果 |
|---------|------|
| `clasp_config_auth` | clasp の認証情報をローカルファイルに保存 |
| `GOOGLE_WORKSPACE_CLI_CONFIG_DIR` | gws CLI の設定ディレクトリをローカルに変更 |
| `CLOUDSDK_CORE_ACCOUNT` | gcloud のアカウントを上書き（認証自体はグローバル共有） |

## Step 2: gws CLI のセットアップ

OAuth クライアントが必要。組織内で共有できる。

```bash
# OAuth クライアントの作成（GCPプロジェクトに紐づく）
gws auth setup --project <GCPプロジェクトID> --login --services sheets,drive,script
```

`--services` でスコープを絞る。全スコープだと `invalid_scope` エラーになることがある。

### 既存の OAuth クライアントを使う場合

`.gws/client_secret.json` を配置してからログイン:
```bash
gws auth login --services sheets,drive,script
```

### 認証の分離確認

```bash
# フォルダ内: 開発アカウント
gws auth status  # → user: dev@example.com

# フォルダ外: 個人アカウント
cd /tmp && gws auth status  # → user: personal@example.com
```

## Step 3: clasp 認証

```bash
# デフォルトクライアントでログイン（push/pull 用）
clasp login

# カスタム OAuth クライアントでログイン（clasp run 用）
# gws と同じ OAuth クライアントを使う
clasp login --creds .gws/client_secret.json
```

**重要:** `clasp run` を使うには、gws と同じカスタム OAuth クライアントでの認証が必要。
デフォルトの clasp OAuth クライアントでは `clasp run` は動かない。

ログイン時、ブラウザのアカウント選択画面で**開発用アカウント**を選ぶこと。
OAuth クライアントが組織内部限定の場合、個人アカウントではログインできない。

## Step 4: GAS プロジェクトの接続

### 既存スプレッドシートの GAS を clone する場合

```bash
mkdir -p gas
clasp clone --rootDir gas <スクリプトID>
```

スクリプトIDは GAS エディタの「プロジェクトの設定」で確認。

### 新規作成の場合

```bash
mkdir -p gas
clasp create --type sheets --title "プロジェクト名" --rootDir gas
```

## Step 5: clasp run の有効化（自己検証ループ）

`clasp run` は GAS 関数をCLIから実行し、return 値を受け取れる。
開発中のテスト自動化に必須。

### 前提条件（3つ）

1. **GAS プロジェクトを GCP プロジェクトに紐付け**
   - GAS エディタ > プロジェクトの設定 > GCP プロジェクト
   - gws auth setup で使った GCP プロジェクトのプロジェクト番号を入力

2. **API実行可能デプロイを作成（GASエディタから1回だけ）**
   - デプロイ → 新しいデプロイ → 種類: **API実行可能**（ライブラリやウェブアプリではない）
   - アクセス: 自分のみ
   - このデプロイは1回作れば以降触る必要なし

3. **clasp をカスタム OAuth クライアントで認証済み**（Step 3 参照）

### 開発サイクル

```bash
# コードを編集 → push → 実行
clasp push        # HEAD コードを更新
clasp run 関数名   # devMode=true で HEAD コードを実行（return 値が表示される）
```

### 注意事項

- `clasp deploy` は使わない。`clasp push` だけでよい
  - `clasp deploy` はバージョン固定デプロイを作るコマンドで、API実行可能デプロイを上書きしてしまう
- `Logger.log()` の出力は `clasp run` では取得できない。テスト結果は `return` で返す
- GAS の BigQuery Advanced Service を使う場合、GCP プロジェクト側でも BigQuery API を有効化する必要がある

### 検証用 ping 関数

プロジェクトに以下を追加しておくとセットアップの検証に使える:

```javascript
function ping() {
  return { ok: true, time: new Date().toISOString() };
}
```

```bash
clasp push && clasp run ping
# → { ok: true, time: '2026-04-21T13:49:11.256Z' }
```

## トラブルシューティング

| エラー | 原因 | 対処 |
|--------|------|------|
| `Script function not found` | API実行可能デプロイがない or 上書きされた | GASエディタから「API実行可能」デプロイを再作成 |
| `org_internal` | OAuth クライアントが組織内部限定で、別組織のアカウントでログインした | ブラウザで正しいアカウントを選択 |
| `invalid_rapt` | clasp がデフォルト OAuth クライアントで認証されている | `clasp login --creds .gws/client_secret.json` で再認証 |
| `BigQuery API has not been used` | GCPプロジェクトでBQ APIが未有効 | `gcloud services enable bigquery.googleapis.com --project=<ID>` |
| `No response` | 関数が undefined を返している | `return` で値を返すようにする |
| `invalid_scope` | gws login で不要なスコープを要求 | `--services` で必要なサービスだけに絞る |

## ファイル構成の例

```
project/
├── .envrc                    # direnv: フォルダ限定の環境変数
├── .gitignore                # .clasprc.json, .gws/ を除外
├── .clasp.json               # clasp プロジェクト設定（git管理OK）
├── .clasprc.json             # clasp 認証情報（git除外）
├── .gws/                     # gws CLI 設定+認証（git除外）
│   ├── client_secret.json
│   └── credentials.enc
└── gas/                      # GAS ソースコード
    ├── appsscript.json
    └── main.js
```
