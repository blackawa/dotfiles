#!/usr/bin/env bash

input=$(cat)

# --- 1. Git info ---
work_dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
if [ -n "$work_dir" ] && git -C "$work_dir" rev-parse --git-dir >/dev/null 2>&1; then
  repo_root=$(git -C "$work_dir" rev-parse --show-toplevel 2>/dev/null)
  repo_name=$(basename "$repo_root")
  branch=$(git -C "$work_dir" branch --show-current 2>/dev/null)
  git_info="${repo_name}(${branch})"
else
  git_info=""
fi

# --- 2. Context window progress bar ---
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

# --- 3. Rate limit remaining (ccusage) ---
export PATH="$PATH:/Users/blackawa/.bun/bin"
rate_info=""
weekly_info=""

if command -v ccusage &>/dev/null; then
  remaining_minutes=$(ccusage blocks --json 2>/dev/null | jq -r '
    first(.blocks[]? | select(.isActive == true)) | .projection.remainingMinutes // empty
  ' 2>/dev/null)
  if [ -n "$remaining_minutes" ] && [ "$remaining_minutes" != "null" ]; then
    rm_int=$(printf '%.0f' "$remaining_minutes")
    if [ "$rm_int" -ge 60 ]; then
      hours=$((rm_int / 60))
      mins=$((rm_int % 60))
      rate_info="⏱ ${hours}h ${mins}m"
    else
      rate_info="⏱ ${rm_int}m"
    fi
  fi

  # --- Weekly usage (ccusage weekly) ---
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
    weekly_m=$((weekly_tokens / 1000000))
    weekly_frac=$(( (weekly_tokens % 1000000) / 100000 ))
    weekly_tokens_str="${weekly_m}.${weekly_frac}M"
    reset_date=$(date -v+${days_to_reset}d +"%m/%d(%a)")
    weekly_info="📅 ${weekly_cost_str} / ${weekly_tokens_str} tok (reset ${reset_date})"
  fi
fi

# --- 4. Model ---
model_name=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // "unknown"' 2>/dev/null)

# --- 5. Session usage ---
input_tok=$(printf '%s' "$input" | jq -r '.context_window.current_usage.input_tokens // 0' 2>/dev/null)
output_tok=$(printf '%s' "$input" | jq -r '.context_window.current_usage.output_tokens // 0' 2>/dev/null)
cache_write=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' 2>/dev/null)
cache_read=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0' 2>/dev/null)
duration_ms=$(printf '%s' "$input" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null)

input_k=$((input_tok / 1000))
output_k=$((output_tok / 1000))
cache_w_k=$((cache_write / 1000))
cache_r_k=$((cache_read / 1000))

duration_s=$((duration_ms / 1000))
dur_m=$((duration_s / 60))
dur_s=$((duration_s % 60))
if [ "$dur_m" -gt 0 ]; then
  dur_str="${dur_m}m${dur_s}s"
else
  dur_str="${dur_s}s"
fi

session_info="in:${input_k}k out:${output_k}k cw:${cache_w_k}k cr:${cache_r_k}k ${dur_str}"

# --- Output (2 lines) ---
# Line 1: repo | progress bar | rate limit | model
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

# Line 2: session usage | weekly usage
line2="${session_info}"
[ -n "$weekly_info" ] && line2="${line2} | ${weekly_info}"

printf '%s\n%s' "$line1" "$line2"
