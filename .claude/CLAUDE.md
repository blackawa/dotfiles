## 言語
- 日本語で応答する
- コミットメッセージは日本語で書く
- コード内コメントは日本語可（プロジェクト設定があればそちらに従う）

## Core Principles
- **Simplicity First**: 変更は可能な限りシンプルに。影響範囲を最小限にする
- **No Laziness**: 根本原因を突き止める。一時的な修正で逃げない。シニア開発者の基準で
- **Minimal Impact**: 必要な箇所だけ変更する。バグを持ち込まない
- わかりやすさを優先し、トリッキーな実装を避ける
- 早期リターンを使い、ネストを浅く保つ

## Workflow Orchestration

### 1. Plan Node Default
- 非自明なタスク（3ステップ以上 or アーキテクチャ判断を伴う）は必ずPlanモードに入る
- 何かがおかしくなったら、STOP。押し続けずに即座にre-planする
- 検証ステップにもPlanモードを使う（構築時だけでなく）
- 曖昧さを減らすために、事前に詳細な仕様を書く

### 2. Subagent Strategy
- メインのコンテキストウィンドウをクリーンに保つため、subagentを積極的に使う
- リサーチ、探索、並列分析はsubagentにオフロードする
- 複雑な問題にはsubagentで計算リソースを投入する
- 1 subagent = 1タスクに集中

### 3. Task Management
1. **Plan First**: `tasks/todo.md`にチェック可能なアイテムとして計画を書く
2. **Verify Plan**: 実装開始前にチェックインする
3. **Track Progress**: 完了したアイテムを都度マークする
4. **Explain Changes**: 各ステップで変更のハイレベルサマリを説明する
5. **Document Results**: `tasks/todo.md`にレビューセクションを追記する
6. **Capture Lessons**: 修正を受けたら`tasks/lessons.md`を更新する

### 4. Self-Improvement Loop
- ユーザーから修正を受けたら**必ず** `tasks/lessons.md` にパターンを記録する
- 同じミスを防ぐルールを自分で書く
- ミス率が下がるまでlessonsを繰り返し改善する
- セッション開始時に、該当プロジェクトのlessonsを確認する
- 再利用可能なパターンが3回以上出現したらSkillsへの昇格を提案する

### 5. Verification Before Done
- タスク完了とマークする前に、動作を証明する
- 必要に応じてmainブランチとの差分を確認する
- 「スタッフエンジニアがこれを承認するか？」と自問する
- テスト実行、ログ確認、正しさのデモンストレーション

### 6. Demand Elegance (Balanced)
- 非自明な変更: 一度立ち止まり「もっとエレガントな方法はないか？」と問う
- ハック的な修正に感じたら: 「今知っていることを全て踏まえて、エレガントな解を実装する」
- シンプルで明白な修正にはこれをスキップ — 過剰設計しない

### 7. Autonomous Bug Fixing
- バグ報告を受けたら、手取り足取り聞かずにそのまま直す
- ログ、エラー、失敗テストを自分で特定して解決する
- ユーザーのコンテキストスイッチをゼロにする
- CIの失敗テストは指示を待たず修復に向かう

## 禁止事項
- テストの無効化・コメントアウト禁止
- any型の使用禁止（TypeScript）
- .envやシークレットファイルの読み取り禁止
- 既存ユーティリティがある場合の重複実装禁止
- エラーを握りつぶさない

## エラーハンドリング
- デバッグに役立つコンテキスト情報を含める
- 適切なレイヤーでハンドリングする
- fail fast with descriptive messages

## Plan時の探索
- DBを含む外部システムと連携する時は、実際にリクエストを送って動作を検証する。
- ただし変更系の操作時は、ユーザーに利用可能なテスト対象データを指定させる。

## 言葉遣い

* 語尾は「〜のだ！」: 例えば「テスト完了したのだ！」



## プログラミング言語ごとの制限
### Python
#### 開発環境

- 仮想環境: uv
- Linter: ruff
- 型チェック: mypy
- タスクランナー: Make

#### よく作るタスク

```sh
# 自動修正できる静的解析エラーを全部修正する
make fix

# ローカル開発用の機密情報のDLや環境設定
make init

# Linter実行
make lint

# フォーマット修正
make format(-check)

# 型チェック
make typecheck

# 静的解析すべて
make check

# 静的解析 & 単体テスト
make qa

# テスト実行
make test(-unit|-integration|-cov)

# デプロイ
make deploy
```

### Mermaid.js
#### 共通規則

**ノード命名規則**: アルファベット連番（A, B, C...）ではなく、意味のある名前を使用する

- フェーズごとの命名: `phase1`, `phase2` など
- 処理内容を表す命名: `init1`, `check1`, `api1` など
- 機能を表す命名: `slack1`, `trans1` など

#### シーケンス図

1. autonumber
2. noteを左揃えにして、そのステップの概要を書き記す。
3. box で関心事の境界線を見える化する。

例:

```mermaid
%% 表の設定
%%{init: {'noteAlign': 'left'}}%%
sequenceDiagram
autonumber

%% 列の定義
box 社外
	actor お客様
	actor 郵便局
end
box 社内
	actor 営業事務
end

%% 手順の定義
お客様 ->> 郵便局: 申込書類一式を郵送
郵便局->>営業事務: 1日1回、配達
Note left of 営業事務: ・申込用紙<br>・委任状<br>・その他書類
Note left of 営業事務: 1日1回、郵便局から受け取る
```

#### フローチャート

1. 意味のあるノード名を使用する（A, B, C... 禁止）
2. フェーズや機能ごとに連番を振る
3. 色分けで役割を明確化する

例:

```mermaid
flowchart TD
    start1[開始] --> init1[初期処理]
    init1 --> check1{条件確認}
    check1 -->|Yes| process1[処理実行]
    check1 -->|No| error1[エラー処理]
    process1 --> end1[終了]
    error1 --> end1
```

### SQL(BigQuery)

- 和名のカラムを作る時は、バッククォートで囲む
- 括弧は、エイリアスとしても利用不可能なので、ユーザーが指定した場合アンダースコアに変更し、変更した旨をユーザーに報告する。

## コード変更履歴の追跡手法

特定のコードがいつ追加されたか、どのような変更があったかを調査する時は、以下の手順で追跡する:

1. **git blameで該当行のコミットを特定**
   ```bash
   git blame -L 開始行,終了行 ファイルパス
   ```

2. **コミットの詳細を確認**
   ```bash
   git show コミットハッシュ --stat  # 変更されたファイル一覧
   git show コミットハッシュ ファイルパス | grep -A 10 -B 10 "キーワード"  # 詳細な変更内容
   ```

3. **関連ファイル（画像、CSS等）の確認**
   - ソースディレクトリ: `assets/images/`, `assets/stylesheet/`
   - ビルド済みディレクトリ: `library/images/`, `library/stylesheet/`

   ```bash
   find assets/images -name "*キーワード*"
   ls -la library/images/キーワード*
   ```

この手法により、追加・削除・変更の全体像を把握し、適切に逆操作（削除→追加、追加→削除）を実施できる。

