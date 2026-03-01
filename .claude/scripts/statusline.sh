#!/usr/bin/env bash

input=$(cat)

# コンテキスト使用率（Claude Code が stdin で渡す）
pct_raw=$(printf '%s' "$input" | jq -r '.context_window.used_percentage' 2>/dev/null)

# プログレスバー生成（10ブロック = 各10%）
if [ -n "$pct_raw" ] && [ "$pct_raw" != "null" ]; then
  pct_num=$(printf '%.0f' "$pct_raw")
  bar=""
  for i in $(seq 1 10); do
    if [ $((i * 10)) -le "$pct_num" ]; then
      bar="${bar}█"
    else
      bar="${bar}░"
    fi
  done
  ctx="${bar} ${pct_num}%"
else
  ctx="░░░░░░░░░░ ...%"
fi

# ccusageの検索パスにbunのbinを含める
export PATH="$PATH:/Users/blackawa/.bun/bin"

# レート制限残時間（ccusage blocks コマンドでアクティブブロックを取得）
if command -v ccusage &>/dev/null; then
  remaining_minutes=$(ccusage blocks --json 2>/dev/null | jq -r '
    first(.blocks[]? | select(.isActive == true)) | .projection.remainingMinutes // empty
  ' 2>/dev/null)

  if [ -n "$remaining_minutes" ] && [ "$remaining_minutes" != "null" ]; then
    if [ "$remaining_minutes" -ge 60 ]; then
      hours=$((remaining_minutes / 60))
      mins=$((remaining_minutes % 60))
      time_str="${hours}h ${mins}m"
    else
      time_str="${remaining_minutes}m"
    fi
    printf '%s | ⏱ %s' "$ctx" "$time_str"
  else
    printf '%s' "$ctx"
  fi
else
  printf '%s' "$ctx"
fi
