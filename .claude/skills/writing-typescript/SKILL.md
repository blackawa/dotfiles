---
name: writing-typescript
description: >
  TypeScript / JavaScript コードの作成・レビュー時に適用する規約とベストプラクティス。
  .ts, .tsx, .js, .jsx ファイルの編集、Node.js/Deno プロジェクトのセットアップ、
  vitest/biome/tsc の実行時に自動で有効化される。
---

# TypeScript Development Standards

## ツールチェイン

| 用途 | 推奨 | 非推奨 |
|------|------|--------|
| パッケージ管理 | pnpm | npm, yarn |
| テスト | vitest | jest |
| Lint + Format | **biome** (v2+) | eslint + prettier（レガシー既存PJのみ）, tslint |
| 型チェック | tsc --noEmit | - |
| ランタイム | Node.js LTS / Deno | - |

> **なぜ Biome か**: ESLint+Prettier比で10〜25倍高速、設定ファイル1つ、
> バイナリ1つ（127+ npmパッケージ不要）。v2でtype-aware linting・プラグイン対応済み。
> ESLintが必要なのは、Biome未対応の特殊プラグイン（a11y等）に依存する既存PJのみ。

## コマンド

```bash
# 依存関係
pnpm add <package>
pnpm add -D <package>
pnpm install

# 品質チェック（変更後は必ずこの順で実行）
pnpm exec tsc --noEmit      # 型チェック
pnpm exec biome check --fix . # lint + format（一括）
pnpm exec vitest run          # テスト
```

### Biome 初期セットアップ

```bash
pnpm add -D --save-exact @biomejs/biome
pnpm exec biome init          # biome.json 生成
```

## biome.json — 推奨設定

```jsonc
{
  "$schema": "https://biomejs.dev/schemas/2.0.0/schema.json",
  "organizeImports": {
    "enabled": true
  },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noExcessiveCognitiveComplexity": "warn"
      },
      "suspicious": {
        "noExplicitAny": "error"
      },
      "style": {
        "noDefaultExport": "error",
        "useImportType": "error",
        "noNonNullAssertion": "error"
      }
    }
  },
  "formatter": {
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "double",
      "semicolons": "always"
    }
  }
}
```

## tsconfig.json — Strict を徹底する

以下のオプションをすべて有効にする。妥協しない。

```jsonc
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

## 型システム

### 必須ルール
- すべての関数シグネチャ・戻り値に型を付ける
- `any` 禁止。`unknown` を使って型ガードで絞り込む
- `as` によるキャストは最終手段。`satisfies` を優先する
- `// @ts-ignore`, `// @ts-expect-error` はテスト内の希少なケースのみ
- Union Discriminator パターンで型を分岐させる
- Generics は意味のある制約付きで使う（`<T>` ではなく `<T extends Base>`）

```typescript
// ✅ Good: satisfies で型安全に
const config = {
  port: 3000,
  host: "localhost",
} satisfies ServerConfig;

// ✅ Good: Discriminated Union
type Result<T> =
  | { ok: true; value: T }
  | { ok: false; error: Error };

function handle(result: Result<User>) {
  if (result.ok) {
    console.log(result.value.name); // 型が絞られる
  }
}

// ❌ Bad: any でごまかす
function parse(data: any) { return data.name; }
// ❌ Bad: as で無理やりキャスト
const user = response as User;
```

### 型定義の方針
- オブジェクトの形状は `interface`（拡張可能）
- Union / Intersection / Mapped Types は `type`
- Zod / Valibot でランタイムバリデーションを兼ねる場合は `z.infer<typeof schema>` で型を導出

```typescript
// ✅ interface: オブジェクトの形状
interface User {
  readonly id: string;
  name: string;
  email: string;
}

// ✅ type: ユニオン・ユーティリティ
type UserRole = "admin" | "member" | "guest";
type UserWithRole = User & { role: UserRole };
```

## コーディングパターン

### 推奨
- `const` をデフォルト、変更が必要な場合のみ `let`。`var` は禁止
- 早期リターンでネストを浅く保つ
- Optional Chaining (`?.`) と Nullish Coalescing (`??`) を活用
- `for...of` ループを優先。`forEach` よりも中断可能で読みやすい
- テンプレートリテラルで文字列結合
- `import type` で型のみのインポートを明示する

```typescript
// ✅ Good: 早期リターン + 型ガード
function getDisplayName(user: User | undefined): string {
  if (!user) return "Anonymous";
  if (!user.name.trim()) return `User#${user.id}`;
  return user.name;
}

// ✅ Good: import type
import type { User } from "./types.js";
import { createUser } from "./service.js";
```

### 禁止
- `enum` — 代わりに `as const` 付きオブジェクトか Union Literal を使う
- `namespace` — ESM のモジュールシステムを使う
- `default export` — named export を使う（リファクタリング安全性）
- `!` (non-null assertion) — 適切な型ガードで代替する
- `eval()`, `Function()` — セキュリティリスク

```typescript
// ✅ Good: as const でenum代替
const Status = {
  Active: "active",
  Inactive: "inactive",
  Pending: "pending",
} as const;
type Status = (typeof Status)[keyof typeof Status];

// ❌ Bad: enum
enum Status { Active, Inactive, Pending }
```

## エラーハンドリング

- カスタムエラークラスを定義する（`cause` チェインを活用）
- `catch(e: unknown)` で捕捉し、`instanceof` で型チェック
- エラーメッセージにデバッグ用コンテキストを含める
- 非同期処理の未処理 rejection を放置しない

```typescript
class ApiError extends Error {
  constructor(
    message: string,
    readonly statusCode: number,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = "ApiError";
  }
}

// ✅ Good: cause チェインで原因を保持
try {
  const data = await fetchUser(id);
} catch (e: unknown) {
  throw new ApiError(`Failed to fetch user ${id}`, 500, { cause: e });
}
```

## テスト

- テストファイルはソースの隣に配置: `foo.ts` → `foo.test.ts`
- テスト名は日本語でも英語でもOK。振る舞いを記述する
- Arrange-Act-Assert パターンに従う
- `vi.mock()` でモジュールモック、`vi.fn()` でスパイ
- エッジケースとエラーパスを必ずテストする

```typescript
import { describe, it, expect, vi } from "vitest";
import { createUser } from "./user-service.js";

describe("createUser", () => {
  it("returns user with generated id", async () => {
    const user = await createUser({ name: "Alice", email: "a@test.com" });

    expect(user.id).toBeDefined();
    expect(user.name).toBe("Alice");
  });

  it("throws on duplicate email", async () => {
    await createUser({ name: "Alice", email: "a@test.com" });

    await expect(
      createUser({ name: "Bob", email: "a@test.com" }),
    ).rejects.toThrow("Email already exists");
  });
});
```

## プロジェクト構成

```
myproject/
├── src/
│   ├── index.ts          # エントリポイント（named export）
│   ├── types.ts           # 共有型定義
│   ├── lib/               # コアロジック
│   ├── utils/             # ユーティリティ
│   └── __tests__/         # 統合テスト（ユニットはコロケーション）
├── package.json
├── biome.json             # Biome設定（lint + format 統合）
├── tsconfig.json
├── vitest.config.ts
└── README.md
```

## ファイル命名規則

```
components/UserProfile.tsx   # PascalCase: React コンポーネント
hooks/useAuth.ts             # camelCase + use prefix: カスタムフック
lib/format-date.ts           # kebab-case: ユーティリティモジュール
types.ts                     # 型定義ファイル
foo.test.ts                  # テストはコロケーション
```

## サプライチェーン安全

- `pnpm audit --audit-level=moderate` を依存追加前に実行
- バージョンは exact（`^` や `~` を付けない）で pin する
- lockfile (`pnpm-lock.yaml`) を必ずコミットする