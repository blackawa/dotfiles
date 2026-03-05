#!/usr/bin/env bash

input=$(cat)

# --- 1. コンテキスト使用率（プログレスバー）+ レート制限残時間 ---
pct_raw=$(printf '%s' "$input" | jq -r '.context_window.used_percentage' 2>/dev/null)
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

export PATH="$PATH:/Users/blackawa/.bun/bin"
rate_info=""
weekly_info=""

if command -v ccusage &>/dev/null; then
  # レート制限残時間（現在のアクティブブロック）
  remaining_minutes=$(ccusage blocks --json 2>/dev/null | jq -r '
    first(.blocks[]? | select(.isActive == true)) | .projection.remainingMinutes // empty
  ' 2>/dev/null)
  if [ -n "$remaining_minutes" ] && [ "$remaining_minutes" != "null" ]; then
    rm_int=$(printf '%.0f' "$remaining_minutes")
    if [ "$rm_int" -ge 60 ]; then
      hours=$((rm_int / 60))
      mins=$((rm_int % 60))
      rate_info="(reset in ${hours}h ${mins}m)"
    else
      rate_info="(reset in ${rm_int}m)"
    fi
  fi

  # --- 2. 今週のusage（ccusage weekly）---
  dow=$(date +%u)  # 1=Mon .. 7=Sun
  if [ "$dow" -eq 7 ]; then
    week_start=$(date +%Y%m%d)
    days_to_reset=7
  else
    week_start=$(date -v-${dow}d +%Y%m%d)
    days_to_reset=$((7 - dow))
  fi

  weekly_json=$(ccusage weekly --json --since "$week_start" 2>/dev/null)
  weekly_cost=$(printf '%s' "$weekly_json" | jq -r '.weekly[0].totalCost // 0' 2>/dev/null)
  weekly_tokens=$(printf '%s' "$weekly_json" | jq -r '.weekly[0].totalTokens // 0' 2>/dev/null)

  if [ -n "$weekly_cost" ] && [ "$weekly_cost" != "0" ] && [ "$weekly_cost" != "null" ]; then
    weekly_cost_str=$(printf '$%.0f' "$weekly_cost")
    # トークンをM単位に（小数1桁）
    weekly_m=$((weekly_tokens / 1000000))
    weekly_frac=$(( (weekly_tokens % 1000000) / 100000 ))
    weekly_tokens_str="${weekly_m}.${weekly_frac}M"

    reset_date=$(date -v+${days_to_reset}d +"%m/%d(%a)")
    weekly_info="今週 ${weekly_cost_str} / ${weekly_tokens_str}トークン (${reset_date}リセット)"
  fi
fi

# --- 出力（2行）---
# 1行目: プログレスバー + レート制限残時間
line1="${ctx}"
[ -n "$rate_info" ] && line1="${line1} ${rate_info}"

# 2行目: 今週のusage
line2="${weekly_info}"

printf '%s\n%s' "$line1" "$line2"
