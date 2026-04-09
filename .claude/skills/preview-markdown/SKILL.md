---
name: preview-markdown
description: >
  Markdownファイルをブラウザでライブプレビューする。mo (k1LoW/mo) を使い、
  ファイル保存時に自動リロードされるプレビューを開く。
  「プレビューして」「ブラウザで確認」「markdownを表示」「moで開いて」
  「レビュー用に開いて」など、Markdownの視覚的確認が必要な場面で使う。
  ファイル作成・編集後の確認フェーズでも積極的に提案すること。
---

# Markdown Preview with mo

`mo` はローカルで動くMarkdownビューアで、ファイル保存のたびにブラウザが自動リロードされる。
一度起動すると常駐し、後からファイルを追加できる。

## 基本ルール

1. **プロジェクトごとにグループを切る** — 複数リポジトリのファイルが混ざらないよう `--target` でグループ名を付ける
2. **グループ名はgitリポジトリ名を使う** — `git rev-parse --show-toplevel` の basename を取得する
3. **ブラウザは初回だけ開く** — 既にサーバーが動いている場合、ファイル追加時は `--no-open` を付ける

## ワークフロー

### Step 1: グループ名を決める

```bash
# gitリポジトリ内ならリポジトリ名を使う
basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || basename "$PWD"
```

### Step 2: moサーバーの状態を確認

```bash
mo --status
```

- 出力があればサーバーは起動済み → ファイル追加時は `--no-open` を付ける
- 出力がなければ初回起動 → そのまま `mo` を実行（自動でブラウザが開く）

### Step 3: ファイルを開く

```bash
# 単一ファイル（初回起動）
mo README.md --target <project-name>

# サーバー起動済みの場合
mo docs/design.md --target <project-name> --no-open

# glob パターンで監視（ディレクトリ内の全.mdを継続監視）
mo --watch 'docs/**/*.md' --target <project-name>
```

### Step 4: 確認が終わったら

ユーザーから「閉じて」「プレビュー止めて」と言われたら:

```bash
# 特定ファイルを閉じる
mo README.md --close --target <project-name>

# サーバー自体を停止（全プロジェクト終了時のみ）
mo --shutdown
```

## 判断基準

| 状況 | コマンド |
|------|---------|
| 1ファイルだけ見たい | `mo <file> -t <project>` |
| ディレクトリ内を全部見たい | `mo -w '<dir>/**/*.md' -t <project>` |
| 追加で別ファイルも見たい | `mo <file> -t <project> --no-open` |
| 別プロジェクトのファイルも見たい | `mo <file> -t <other-project>` |

## 注意事項

- `mo` はバックグラウンドで動作するため、コマンドは即座に返る
- ポートはデフォルト 6275。複数セッション不要（1サーバーで複数グループを管理できる）
- セッションは自動保存される。`mo --clear` でリセット可能
