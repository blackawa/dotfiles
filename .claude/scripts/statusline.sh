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

# --- 出力の組み立て ---
parts=()
[ -n "$git_info" ] && parts+=("$git_info")
parts+=("$ctx")
[ -n "$rate_info" ] && parts+=("$rate_info")
[ -n "$model_name" ] && parts+=("$model_name")

output=""
for part in "${parts[@]}"; do
  if [ -z "$output" ]; then
    output="$part"
  else
    output="${output} | ${part}"
  fi
done

printf '%s' "$output"
