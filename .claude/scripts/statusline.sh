#!/usr/bin/env bash

# Weekly budget for progress bar (adjust as needed)
WEEKLY_BUDGET_USD=200

input=$(cat)

# --- Git info ---
work_dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
if [ -n "$work_dir" ] && git -C "$work_dir" rev-parse --git-dir >/dev/null 2>&1; then
  repo_root=$(git -C "$work_dir" rev-parse --show-toplevel 2>/dev/null)
  repo_name=$(basename "$repo_root")
  branch=$(git -C "$work_dir" branch --show-current 2>/dev/null)
  git_info="${repo_name}(${branch})"
else
  git_info=""
fi

# --- Model ---
model_name=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // "unknown"' 2>/dev/null)

# --- Helper: build progress bar (arg: percentage 0-100) ---
build_bar() {
  local pct=$1
  local b=""
  for i in $(seq 1 10); do
    if [ $((i * 10)) -le "$pct" ]; then
      b="${b}█"
    else
      b="${b}░"
    fi
  done
  printf '%s' "$b"
}

# --- Session: context window usage + rate limit reset ---
pct_raw=$(printf '%s' "$input" | jq -r '.context_window.used_percentage' 2>/dev/null)
if [ -n "$pct_raw" ] && [ "$pct_raw" != "null" ]; then
  session_pct=$(printf '%.0f' "$pct_raw")
else
  session_pct=0
fi
session_bar=$(build_bar "$session_pct")

export PATH="$PATH:/Users/blackawa/.bun/bin"
session_reset=""
weekly_part=""

if command -v ccusage &>/dev/null; then
  # Rate limit remaining (current active block)
  remaining_minutes=$(ccusage blocks --json 2>/dev/null | jq -r '
    first(.blocks[]? | select(.isActive == true)) | .projection.remainingMinutes // empty
  ' 2>/dev/null)
  if [ -n "$remaining_minutes" ] && [ "$remaining_minutes" != "null" ]; then
    rm_int=$(printf '%.0f' "$remaining_minutes")
    if [ "$rm_int" -ge 60 ]; then
      hours=$((rm_int / 60))
      mins=$((rm_int % 60))
      session_reset="(resets in ${hours}h ${mins}m)"
    else
      session_reset="(resets in ${rm_int}m)"
    fi
  fi

  # --- Week: weekly cost usage + reset date ---
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

  if [ -n "$weekly_cost" ] && [ "$weekly_cost" != "null" ]; then
    # Calculate percentage against budget
    weekly_pct=$(printf '%.0f' "$(printf '%s %s' "$weekly_cost" "$WEEKLY_BUDGET_USD" | awk '{printf "%.0f", ($1/$2)*100}')")
    [ "$weekly_pct" -gt 100 ] && weekly_pct=100
    weekly_bar=$(build_bar "$weekly_pct")

    reset_date=$(LC_TIME=en_US.UTF-8 date -v+${days_to_reset}d +"%b %-d")
    weekly_part=" | week ${weekly_bar} ${weekly_pct}%(resets ${reset_date})"
  fi
fi

# --- Output (2 lines) ---
# Line 1: repo | model
line1_parts=()
[ -n "$git_info" ] && line1_parts+=("$git_info")
[ -n "$model_name" ] && line1_parts+=("$model_name")

line1=""
for part in "${line1_parts[@]}"; do
  if [ -z "$line1" ]; then
    line1="$part"
  else
    line1="${line1} | ${part}"
  fi
done

# Line 2: session bar + reset | week bar + reset
line2="session ${session_bar} ${session_pct}%${session_reset}${weekly_part}"

printf '%s\n%s' "$line1" "$line2"
