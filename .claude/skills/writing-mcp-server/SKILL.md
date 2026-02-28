---
name: writing-mcp-server
description: >
  MCPサーバー実装の作成・レビュー時に適用する規約とベストプラクティス。
  MCP実装タスクの実行時に自動で有効化される。
---

MCPサーバー構築時に参照するスキル。設計原則→実装→運用の順で読む。

---

## 1. 設計原則

### MCPはREST APIではない

MCPサーバーのクライアントはLLMエージェントである。全ツール定義（名前・説明・スキーマ）がコンテキストウィンドウに載るため、ツール数・スキーマサイズがトークンコストと精度に直結する。

**ワークフロー単位でツールを設計する。** 個々のAPIエンドポイントを1:1でラップしない。ユーザーが達成したいタスク単位で1ツールにまとめる。例: GitHub issue作成時に labels・assignees も同一ツールの入力に含め、1回の呼び出しで完結させる。

**冪等に作る。** エージェントはリトライ・並列化する。同じ入力で同じ結果を返すこと。リスト系はページネーショントークン/カーソルで応答を小さく保つ。

### ツール命名

- **snake_case**: `search_users`, `create_project`（LLMトークナイザーと相性良）
- **サービスプレフィックス必須**: `slack_send_message`（他MCPサーバーとの併用前提）
- **動詞始まり**: `get_`, `list_`, `search_`, `create_`, `update_`, `delete_`
- **禁止文字**: スペース、`.`、`()`、`[]`（ツール呼び出しが壊れる）

### ツール説明文テンプレート

LLMのツール選択精度に最も影響する要素。以下の構造を守る：

```
[1行] 何をするか
[できること/できないことの明確化]
[Args] 各パラメータの型・制約・例
[Returns] 出力スキーマ
[Examples] 自然言語→パラメータのマッピング 2-3件
[Error cases] 代表的エラーと原因
```

### レスポンス設計

- `structuredContent` で型付き出力を返す（2025-06 spec の `outputSchema` 対応）
- ページネーション: `has_more`, `next_offset`/`next_cursor`, `total` を常に返す。デフォルト20-50件
- 文字数上限（例: 25,000文字）を設け、超過時はトランケート+メッセージ付与
- **エラーはエージェントが次のアクションを判断できる内容にする**:
  - ❌ `"Access denied"`
  - ✅ `"Error: Permission denied. API_TOKEN needs 'read:items' scope."`
  - ❌ `"Not found"`
  - ✅ `"Error: Item 'abc-123' not found. Use myservice_search_items to find valid IDs."`

### アノテーション

| キー | 型 | 意味 |
|---|---|---|
| `readOnlyHint` | bool | 環境を変更しない |
| `destructiveHint` | bool | 破壊的変更の可能性 |
| `idempotentHint` | bool | 再実行が安全 |
| `openWorldHint` | bool | 外部と通信する |

---

## 2. 実装パターン（TypeScript / tsx）

ビルドステップなしで `tsx src/index.ts` で直接実行する構成を標準とする。

### 主要ライブラリ

```
@modelcontextprotocol/sdk   # MCP SDK
zod                          # 入力バリデーション
express                      # Streamable HTTP 時のみ
tsx                          # TypeScript 直接実行（devDependencies）
```

### プロジェクト構成

```
{service}-mcp-server/
├── src/
│   ├── index.ts       # サーバー初期化 + トランスポート
│   ├── tools/         # ツール実装（ドメイン分割）
│   ├── services/      # API クライアント共通化
│   └── constants.ts   # API_URL, CHARACTER_LIMIT 等
└── package.json       # "start": "tsx src/index.ts"
```

命名: `{service}-mcp-server`（ハイフン区切り）。

### SDK API 早見表

| ✅ 使う | ❌ 非推奨 |
|---|---|
| `server.registerTool()` | `server.tool()` |
| `server.registerResource()` | `server.setRequestHandler(...)` |
| `server.registerPrompt()` | 手動ハンドラ登録 |

### ツール登録の要点

```typescript
server.registerTool(
  "myservice_search_items",
  {
    title: "Search Items",
    description: `...`, // セクション1のテンプレートに従う
    inputSchema: {
      query: z.string().min(1).max(200).describe("検索文字列"),
      limit: z.number().int().min(1).max(100).default(20),
    },
    annotations: { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: true },
  },
  async ({ query, limit }) => {
    try {
      const data = await apiRequest("/search", { q: query, limit });
      return {
        content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
        structuredContent: data,  // 型付き出力
      };
    } catch (error) {
      return { isError: true, content: [{ type: "text", text: handleError(error) }] };
    }
  }
);
```

**守るべき点:**
- Zod スキーマに `.describe()` を必ず付ける（LLMのパラメータ理解に必要）
- `structuredContent` で構造化データも返す
- エラーは `isError: true` + `content` で返す（プロトコルレベルエラーにしない）
- `.strict()` で余分なフィールドを拒否する

### Resource 登録

ツールとの使い分け: シンプルな URI→値のマッピング → Resource / 複雑な入力・副作用 → Tool

```typescript
server.registerResource(
  { uri: "config://settings/{key}", name: "Settings", mimeType: "application/json" },
  async (uri) => {
    const key = uri.match(/config:\/\/settings\/(.+)$/)?.[1]!;
    return { contents: [{ uri, mimeType: "application/json", text: JSON.stringify(getConfig(key)) }] };
  }
);
```

### トランスポート

**stdio**（ローカル・CLI）: `StdioServerTransport` で接続。**stdout は MCP メッセージ専用。ログは必ず stderr へ。**

**Streamable HTTP**（リモート・マルチクライアント）: express + `StreamableHTTPServerTransport`。リクエストごとにトランスポートを生成（ステートレス）。`/health` エンドポイントを必ず用意。

環境変数 `TRANSPORT=stdio|http` で切替する。

### 共通ユーティリティの切り出し

API呼び出し・エラーハンドリング・レスポンスフォーマットは必ず共通関数化（DRY）。ツールごとにコピペしない。

- `services/api.ts`: 共通 fetch ラッパー（ベースURL、認証ヘッダ、タイムアウト、エラーthrow）
- `services/errors.ts`: ステータスコード別にエージェント向けメッセージを返す関数
- `constants.ts`: `API_URL`, `CHARACTER_LIMIT`, `DEFAULT_LIMIT` 等

---

## 3. 生 HTTP / stdio（SDK なし）

SDKを使わず JSON-RPC 2.0 だけで実装するパターン。Go, Rust, Java 等で有用。

### プロトコル要点

- 全通信は **JSON-RPC 2.0**（UTF-8）
- `id` ありメッセージ → レスポンス必須。`id` なし（通知） → レスポンス不要（HTTP は 202）
- 標準エラーコード: `-32700` Parse error / `-32600` Invalid Request / `-32601` Method not found / `-32602` Invalid params

### 処理すべきメソッド

| メソッド | 種別 | 返すもの |
|---|---|---|
| `initialize` | request | `protocolVersion`, `capabilities`, `serverInfo` |
| `notifications/initialized` | notification | なし（HTTP: 202 / stdio: 無応答） |
| `tools/list` | request | `{ tools: ToolDefinition[] }` |
| `tools/call` | request | `{ content: ContentBlock[] }` or `{ isError, content }` |

### Streamable HTTP 注意点

- **単一エンドポイント**（例: `/mcp`）で POST/GET/DELETE を処理
- POST: JSON-RPC送信。レスポンスは `application/json` or `text/event-stream`
- GET: SSEストリーム開設（任意。非対応なら `405`）
- `Mcp-Session-Id`: サーバーが initialize 時に発行→以降クライアントが付与（ステートレスなら省略可）
- `MCP-Protocol-Version: 2025-06-18`: 2025-06 spec 以降のヘッダ

### stdio 注意点

- 改行区切りの JSON-RPC（メッセージ内に改行不可）
- **stdout は MCP メッセージ専用**。ログ・デバッグは stderr
- クライアントがサーバープロセスのライフサイクルを管理

---

## 4. 本番運用

### トランスポート選択

| stdio | Streamable HTTP |
|---|---|
| ローカル・CLI・デスクトップ統合 | リモート・クラウド・マルチクライアント |

SSE 単体トランスポートは非推奨（Streamable HTTP に統合済み）。

### セキュリティ

- **機密情報をコードやローカルに保存しない**: トークン・キーは環境変数経由。本番はシークレット管理サービスを使う
- **入力バリデーション**: Zod/Pydantic でスキーマレベル強制。パストラバーサル・インジェクションに注意
- **Origin ヘッダ検証**: Streamable HTTP では DNS リバインディング防止のため必須
- **localhost バインド**: ローカル実行時は `127.0.0.1`（`0.0.0.0` は NG）
- **最小権限**: 読み取り専用ツールをデフォルトに。書き込みは明示的承認フローを設ける

### 監視

- **構造化ログ**: ツール名、リクエストID、レイテンシ、成否を JSON Lines で出力
- **ヘルスチェック**: HTTP の場合 `/health` を必ず用意
- **stdio のログは stderr**: stdout は MCP 専用

### テスト

```bash
npx @modelcontextprotocol/inspector
```

MCP Inspector で全ツールの正常系・エラー系（認証失敗、レート制限、不正入力、タイムアウト）を確認。

---

## 5. チェックリスト

- [ ] ツールはワークフロー単位（API 1:1 ラップではない）
- [ ] 命名: `{service}_{verb}_{resource}` の snake_case
- [ ] 説明文: Args / Returns / Examples / Error cases 完備
- [ ] アノテーション正確に設定
- [ ] ページネーション対応（has_more, next_offset）
- [ ] Zod `.strict()` + `.describe()` 全パラメータ
- [ ] `structuredContent` でオブジェクト返却
- [ ] 共通ロジック DRY 化（API・エラー処理・フォーマット）
- [ ] CHARACTER_LIMIT による応答サイズ制限
- [ ] stdio: stdout に MCP 以外を出力しない
- [ ] HTTP: `/health` + Origin 検証
- [ ] 機密情報はコード・ローカルに保存しない
- [ ] 読み取り/書き込みツールの分離
- [ ] MCP Inspector で全ツールテスト済み