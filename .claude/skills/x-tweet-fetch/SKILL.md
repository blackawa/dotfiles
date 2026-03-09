---
name: x-tweet-fetch
description: >
  X(Twitter)の特定投稿URLから原文を直接取得するスキル。
  fxtwitter API（APIキー不要・無料）を使用し、ロングポスト（記事形式）の全文取得にも対応。
  以下のようなリクエストで発動する:
  「この投稿を取得」「ツイートの内容」「このURLの投稿を見せて」
  「このXの投稿を読んで」「このツイートを取得して」。
  X/TwitterのURLが含まれるメッセージで、検索ではなく特定投稿の内容取得が目的の場合に使う。

  x-ai-search との棲み分け:
  - 検索（キーワードで複数投稿を探す）→ x-ai-search
  - 特定投稿の取得（URLやIDで1件取得）→ x-tweet-fetch
---

# X Tweet Fetch Skill

## Overview

fxtwitter API を使い、X(Twitter)の特定投稿の全文を取得するスキル。
APIキー不要・無料で利用可能。ロングポスト（記事形式）の全文取得にも対応。

## Prerequisites

- Node.js がインストールされていること
- `tsx` が利用可能であること（なければ `npx tsx` で実行）
- APIキーは不要

## Usage

### URL指定で取得

```bash
npx tsx <skill-path>/scripts/x_tweet_fetch.ts --url "https://x.com/user/status/123456"
```

### ID指定で取得

```bash
npx tsx <skill-path>/scripts/x_tweet_fetch.ts --id "123456"
```

### Options

| Option     | Default | Description                        |
|------------|---------|------------------------------------|
| `--url`    | -       | X投稿のURL（`--id`と排他）         |
| `--id`     | -       | ツイートID（`--url`と排他）        |
| `--format` | `text`  | 出力形式 (`text`, `json`)          |
| `--dry-run`| false   | リクエストURL確認のみ              |

### Examples

ロングポストの全文取得:
```bash
npx tsx scripts/x_tweet_fetch.ts --url "https://x.com/katanalarp/status/2029928471632224486"
```

JSON形式で取得:
```bash
npx tsx scripts/x_tweet_fetch.ts --url "https://x.com/katanalarp/status/2029928471632224486" --format json
```

通常ツイートの取得:
```bash
npx tsx scripts/x_tweet_fetch.ts --url "https://x.com/KatanaLarp/status/2030046813420421291"
```

## Workflow

1. ユーザーがX投稿のURLを提示する
2. スクリプトを実行して投稿の全文を取得する
3. 取得した内容をユーザーの目的に合わせて提示・分析する

### 結果の提示ガイドライン

- ロングポストは構造を活かしてMarkdown形式で提示する
- メタデータ（投稿者、日時、エンゲージメント）を冒頭に添える
- ユーザーが要約を求めた場合は、全文取得後に要約する

## Technical Details

- **API**: fxtwitter (FixTweet)
- **エンドポイント**: `GET https://api.fxtwitter.com/{username}/status/{id}`
- **認証**: 不要
- **料金**: 無料
- **レート制限**: 特に明記なし（常識的な範囲で使用すること）

### レスポンス構造

```
tweet.text              → 通常ツイートの本文
tweet.article.content   → ロングポスト（記事）の全文（blocks配列）
tweet.article.title     → 記事タイトル
tweet.author            → name, screen_name 等
tweet.likes / retweets / views / bookmarks / replies → エンゲージメント
tweet.created_at        → 投稿日時
tweet.media             → 画像・動画（あれば）
```

## Error Handling

| Error                | Action                                     |
|----------------------|--------------------------------------------|
| HTTP 404             | URLまたはIDが無効。入力を確認する          |
| ネットワークエラー   | リトライを試みる                           |
| tweet データなし     | レスポンス形式の変更の可能性               |

## Cost

無料。APIキー不要。
