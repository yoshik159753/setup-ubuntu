#!/bin/bash
input=$(cat)

join_parts() {
  local result=""
  local first=true
  for part in "$@"; do
    if $first; then
      result="$part"
      first=false
    else
      result="${result} | ${part}"
    fi
  done
  printf "%s" "$result"
}

# ── Line 1: model / effort / thinking ──
line1_parts=()

model_id=$(echo "$input" | jq -r '.model.id // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
if [ -n "$model_id" ] && [ -n "$ctx_size" ]; then
  ctx_size_m=$(awk "BEGIN {printf \"%.1f\", $ctx_size/1000000}")
  line1_parts+=("${model_id}(${ctx_size_m}M)")
elif [ -n "$model_id" ]; then
  line1_parts+=("$model_id")
fi

effort=$(echo "$input" | jq -r '.effort.level // empty')
[ -n "$effort" ] && line1_parts+=("effort[${effort}]")

thinking=$(echo "$input" | jq -r '.thinking.enabled // false')
[ "$thinking" = "true" ] && line1_parts+=("thinking")

# ── Line 2: context / rate limits ──
line2_parts=()

ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$ctx_pct" ]; then
  ctx_int=$(printf "%.0f" "$ctx_pct")
  exceeds=$(echo "$input" | jq -r '.context_window.exceeds_200k_tokens // false')
  warning=""
  [ "$exceeds" = "true" ] && warning=" 200k!"
  if [ "$ctx_int" -ge 80 ]; then
    line2_parts+=("$(printf "\033[1;31mctx[%d%%]%s\033[00m" "$ctx_int" "$warning")")
  else
    line2_parts+=("ctx[${ctx_int}%]${warning}")
  fi
fi

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_pct" ]; then
  five_int=$(printf "%.0f" "$five_pct")
  five_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  line2_parts+=("5h ctx[${five_int}%]")
  if [ -n "$five_resets" ]; then
    resets_time=$(date -d "@${five_resets}" +%H:%M 2>/dev/null)
    [ -n "$resets_time" ] && line2_parts+=("5h resets[${resets_time}]")
  fi
fi

# ── Line 3+: directories ──
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
mapfile -t added_dirs < <(echo "$input" | jq -r '.workspace.added_dirs[]? // empty' 2>/dev/null)

# ── Assemble ──
line1=$(join_parts "${line1_parts[@]}")
line2=$(join_parts "${line2_parts[@]}")

output=""
[ -n "$line1" ] && output="${line1}"
[ -n "$line2" ] && output="${output:+${output}\n}${line2}"
[ -n "$current_dir" ] && output="${output:+${output}\n}${current_dir}"
for dir in "${added_dirs[@]}"; do
  [ -n "$dir" ] && output="${output:+${output}\n}${dir}"
done

printf "%b" "$output"
