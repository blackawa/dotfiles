#!/usr/bin/env npx tsx
/**
 * x_tweet_fetch.ts - X (Twitter) 投稿取得 via fxtwitter API
 *
 * fxtwitter API を使って特定の X 投稿の全文を取得する。
 * APIキー不要・無料で利用可能。ロングポスト（記事形式）にも対応。
 *
 * Usage:
 *   npx tsx x_tweet_fetch.ts --url "https://x.com/user/status/123" [options]
 *   npx tsx x_tweet_fetch.ts --id "123" [options]
 */

import { parseArgs } from "node:util";

// ---------------------------------------------------------------------------
// CLI Args
// ---------------------------------------------------------------------------
const { values: args } = parseArgs({
  options: {
    url: { type: "string", short: "u" },
    id: { type: "string" },
    format: { type: "string", short: "f", default: "text" },
    "dry-run": { type: "boolean", default: false },
    help: { type: "boolean", short: "h", default: false },
  },
  strict: true,
});

if (args.help) {
  console.log(`
x_tweet_fetch.ts - X (Twitter) 投稿取得 via fxtwitter API

Usage:
  npx tsx x_tweet_fetch.ts --url "https://x.com/user/status/123" [options]
  npx tsx x_tweet_fetch.ts --id "123" [options]

Options:
  --url, -u     X投稿のURL (--idと排他)
  --id          ツイートID (--urlと排他)
  --format, -f  出力形式: text, json (default: text)
  --dry-run     リクエストURL確認のみ
  --help, -h    ヘルプ表示
`);
  process.exit(0);
}

if (!args.url && !args.id) {
  console.error("Error: --url または --id が必要です。--help で使い方を確認してください。");
  process.exit(1);
}

if (args.url && args.id) {
  console.error("Error: --url と --id は同時に指定できません。");
  process.exit(1);
}

// ---------------------------------------------------------------------------
// URL/ID パース
// ---------------------------------------------------------------------------
interface TweetRef {
  username: string;
  id: string;
}

function extractTweetRef(input: string): TweetRef {
  // URL パターン: x.com または twitter.com
  const urlMatch = input.match(/(?:x\.com|twitter\.com)\/(\w+)\/status\/(\d+)/);
  if (urlMatch) {
    return { username: urlMatch[1], id: urlMatch[2] };
  }

  // 数字のみならIDとして扱う（usernameは "i" プレースホルダー）
  if (/^\d+$/.test(input)) {
    return { username: "i", id: input };
  }

  console.error(`Error: 無効な入力です: ${input}`);
  console.error("X投稿のURL (https://x.com/user/status/123) またはツイートID (数字) を指定してください。");
  process.exit(1);
}

const tweetRef = extractTweetRef(args.url || args.id || "");
const apiUrl = `https://api.fxtwitter.com/${tweetRef.username}/status/${tweetRef.id}`;
const outputFormat = args.format === "json" ? "json" : "text";

if (args["dry-run"]) {
  console.log(`Request URL: ${apiUrl}`);
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Article blocks → Markdown 変換
// ---------------------------------------------------------------------------
interface ArticleBlock {
  type: string;
  text: string;
}

function blocksToMarkdown(blocks: ArticleBlock[]): string {
  return blocks
    .map((block) => {
      switch (block.type) {
        case "header-two":
          return `## ${block.text}`;
        case "header-three":
          return `### ${block.text}`;
        case "unordered-list-item":
          return `- ${block.text}`;
        case "code-block":
          return `\`\`\`\n${block.text}\n\`\`\``;
        default:
          return block.text;
      }
    })
    .join("\n");
}

// ---------------------------------------------------------------------------
// 数値フォーマット
// ---------------------------------------------------------------------------
function formatNumber(n: number | undefined): string {
  if (n === undefined || n === null) return "0";
  return n.toLocaleString();
}

// ---------------------------------------------------------------------------
// メイン処理
// ---------------------------------------------------------------------------
async function fetchTweet(): Promise<void> {
  const startTime = Date.now();

  const response = await fetch(apiUrl);

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(`API Error (${response.status}): ${response.statusText}\n${errorBody}`);
    process.exit(1);
  }

  const data = await response.json();
  const elapsed = Date.now() - startTime;

  if (!data.tweet) {
    console.error("Error: レスポンスに tweet データが含まれていません。");
    console.error("Response:", JSON.stringify(data, null, 2));
    process.exit(1);
  }

  const tweet = data.tweet;

  // 本文取得: article（ロングポスト）があればそちらを優先
  let body: string;
  let articleTitle: string | undefined;
  if (tweet.article?.content?.blocks) {
    body = blocksToMarkdown(tweet.article.content.blocks);
    articleTitle = tweet.article.title;
  } else {
    body = tweet.text || "";
  }

  if (outputFormat === "json") {
    const output = {
      meta: {
        api: "fxtwitter",
        elapsed_ms: elapsed,
      },
      tweet: {
        id: tweet.id,
        url: tweet.url,
        author: {
          name: tweet.author?.name,
          screen_name: tweet.author?.screen_name,
        },
        created_at: tweet.created_at,
        article_title: articleTitle || null,
        text: body,
        engagement: {
          likes: tweet.likes,
          retweets: tweet.retweets,
          views: tweet.views,
          bookmarks: tweet.bookmarks,
          replies: tweet.replies,
        },
        media: tweet.media || null,
      },
    };
    console.log(JSON.stringify(output, null, 2));
  } else {
    // text 出力
    const author = tweet.author;
    const displayName = author?.name || "Unknown";
    const screenName = author?.screen_name || "unknown";

    console.log(`## Tweet by ${displayName} (@${screenName})`);
    console.log(`投稿日時: ${tweet.created_at || "不明"}`);
    console.log(
      `いいね: ${formatNumber(tweet.likes)} | RT: ${formatNumber(tweet.retweets)} | 閲覧: ${formatNumber(tweet.views)} | ブックマーク: ${formatNumber(tweet.bookmarks)}`
    );
    console.log("---\n");

    if (articleTitle) {
      console.log(`# ${articleTitle}\n`);
    }
    console.log(body);

    console.log("\n---");
    console.log(`URL: ${tweet.url || `https://x.com/${screenName}/status/${tweetRef.id}`}`);

    // メタ情報（stderr）
    console.error(`\n[meta] api=fxtwitter elapsed=${elapsed}ms`);
  }
}

fetchTweet().catch((err) => {
  console.error(`Fatal error: ${err.message}`);
  process.exit(1);
});
