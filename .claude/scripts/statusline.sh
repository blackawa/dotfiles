#!/usr/bin/env bash

input=$(cat)

# --- 1. Gitリポジトリのフォルダ名 ---
work_dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
if [ -n "$work_dir" ] && git -C "$work_dir" rev-parse --git-dir >/dev/null 2>&1; then
  repo_root=$(git -C "$work_dir" rev-parse --show-toplevel 2>/dev/null)
  repo_name=$(basename "$repo_root")
  branch=$(git -C "$work_dir" branch --show-current 2>/dev/null)
  git_info="${repo_name}(${branch})"
else
  git_info=""
fi

# --- 2. コンテキスト使用率（プログレスバー形式）---
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

# --- 3. レート制限残時間（ccusage）---
export PATH="$PATH:/Users/blackawa/.bun/bin"
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
    rate_info="⏱ ${time_str}"
  else
    rate_info=""
  fi
else
  rate_info=""
fi

# --- 4. 現在のモデル ---
model_name=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // "unknown"' 2>/dev/null)

# --- 5. /usage 情報（トークン・コスト・実行時間）---
input_tok=$(printf '%s' "$input" | jq -r '.context_window.current_usage.input_tokens // 0' 2>/dev/null)
output_tok=$(printf '%s' "$input" | jq -r '.context_window.current_usage.output_tokens // 0' 2>/dev/null)
cache_write=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' 2>/dev/null)
cache_read=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0' 2>/dev/null)
cost_usd=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
duration_ms=$(printf '%s' "$input" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null)

# トークンをk単位に
input_k=$((input_tok / 1000))
output_k=$((output_tok / 1000))
cache_w_k=$((cache_write / 1000))
cache_r_k=$((cache_read / 1000))

# 実行時間を分:秒に
duration_s=$((duration_ms / 1000))
dur_m=$((duration_s / 60))
dur_s=$((duration_s % 60))
if [ "$dur_m" -gt 0 ]; then
  dur_str="${dur_m}m${dur_s}s"
else
  dur_str="${dur_s}s"
fi

# コストを整形
cost_str=$(printf '$%.2f' "$cost_usd")

usage_info="in:${input_k}k out:${output_k}k cw:${cache_w_k}k cr:${cache_r_k}k | ${cost_str} | ${dur_str}"

# --- 出力の組み立て（2行）---
# 1行目: リポジトリ | プログレスバー | レート制限 | モデル
line1_parts=()
[ -n "$git_info" ] && line1_parts+=("$git_info")
line1_parts+=("$ctx")
[ -n "$rate_info" ] && line1_parts+=("$rate_info")
[ -n "$model_name" ] && line1_parts+=("$model_name")

line1=""
for part in "${line1_parts[@]}"; do
  if [ -z "$line1" ]; then
    line1="$part"
  else
    line1="${line1} | ${part}"
  fi
done

# 2行目: トークン使用量 | コスト | 実行時間
line2="$usage_info"

printf '%s\n%s' "$line1" "$line2"
