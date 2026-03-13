#!/bin/bash

# Claude Code StatusLine - mirrors Powerlevel10k prompt
# Based on ~/.dotfiles/zsh/p10k.customizations.zsh

# Function to generate status line
generate_status_line() {
  local input="$1"

  cwd=$(echo "$input" | python3 -c "import sys, json; print(json.load(sys.stdin).get('workspace', {}).get('current_dir', ''))")
  project_dir=$(echo "$input" | python3 -c "import sys, json; print(json.load(sys.stdin).get('workspace', {}).get('project_dir', ''))")

  # Change to cwd for git commands
  cd "$cwd" 2>/dev/null || cd ~

  # Initialize segments
  segments=()

  # Add current time (will be displayed first)
  current_time=$(date '+%H:%M:%S')
  segments+=("$(printf '\033[90m%s\033[0m' "$current_time")")

  # Store directory info for later (will be displayed last)
  dir_display="$cwd"

  # Git status & branch
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    branch=$(git branch --show-current 2>/dev/null)

    # PR number (orange for open, purple for merged)
    pr_info=$(git config --get branch."$branch".github-pr-owner-number 2>/dev/null)
    if [[ -n "$pr_info" ]]; then
      pr_number=$(echo "$pr_info" | awk -F "#" '{print $3}')
      repo=$(echo "$pr_info" | awk -F "#" '{print $1 "/" $2}')

      if [[ -n "$pr_number" ]]; then
        # Check cache
        cache=$(git config --get branch."$branch".github-pr-state-cache 2>/dev/null)
        pr_color='\033[38;5;208m'  # Orange default

        if [[ -n "$cache" ]]; then
          cached_state=$(echo "$cache" | cut -d: -f1)
          if [[ "$cached_state" == "MERGED" ]]; then
            pr_color='\033[38;5;135m'  # Purple
          fi
        fi

        segments+=("$(printf '%b#%s\033[0m' "$pr_color" "$pr_number")")
      fi
    fi

    # Branch & status indicators
    if [[ -n "$branch" ]]; then
      status=$(git --no-optional-locks status --porcelain 2>/dev/null)

      # Count status indicators
      staged=0
      modified=0
      untracked=0
      deleted=0

      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        x="${line:0:1}"
        y="${line:1:1}"

        # Staged changes (index)
        [[ "$x" =~ [MADRC] ]] && ((staged++))

        # Unstaged modifications
        [[ "$y" == "M" ]] && ((modified++))

        # Deleted files
        [[ "$y" == "D" ]] && ((deleted++))

        # Untracked files
        [[ "$x" == "?" ]] && ((untracked++))
      done <<< "$status"

      # Build branch segment without icon
      if [[ -n "$status" ]]; then
        # Modified (cyan)
        branch_seg="$(printf '\033[36m%s\033[0m' "$branch")"
      else
        # Clean (green)
        branch_seg="$(printf '\033[32m%s\033[0m' "$branch")"
      fi

      # Add status indicators
      indicators=""

      # Commits ahead/behind upstream (first)
      upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null)
      if [[ -n "$upstream" ]]; then
        ahead=$(git rev-list --count "@{upstream}..HEAD" 2>/dev/null)
        behind=$(git rev-list --count "HEAD..@{upstream}" 2>/dev/null)
        [[ $behind -gt 0 ]] && indicators+="$(printf '\033[36m↓%d\033[0m ' "$behind")"
        [[ $ahead -gt 0 ]] && indicators+="$(printf '\033[36m↑%d\033[0m ' "$ahead")"
      fi

      # File status indicators
      [[ $staged -gt 0 ]] && indicators+="$(printf '\033[32m+%d\033[0m ' "$staged")"
      [[ $modified -gt 0 ]] && indicators+="$(printf '\033[33m!%d\033[0m ' "$modified")"
      [[ $deleted -gt 0 ]] && indicators+="$(printf '\033[31m-%d\033[0m ' "$deleted")"
      [[ $untracked -gt 0 ]] && indicators+="$(printf '\033[31m?%d\033[0m ' "$untracked")"

      # Trim trailing space
      indicators="${indicators% }"

      # Store branch info for later use (will be displayed in model position)
      branch_info="$branch_seg"
      if [[ -n "$indicators" ]]; then
        branch_info="$(printf '%b %s' "$branch_seg" "$indicators")"
      fi
    fi
  fi

  # Branch name (replacing model name)
  if [[ -n "$branch_info" ]]; then
    segments+=("$branch_info")
  fi

  # Context window with gradient bar
  # Auto-compact buffer (33K) from Claude Code source
  _ctx_tokens=$(echo "$input" | python3 -c "import sys, json; data=json.load(sys.stdin); usage=data.get('context_window', {}).get('current_usage', {}); print(usage.get('input_tokens', 0) + usage.get('cache_creation_input_tokens', 0) + usage.get('cache_read_input_tokens', 0))")
  _ctx_size=$(echo "$input" | python3 -c "import sys, json; print(json.load(sys.stdin).get('context_window', {}).get('context_window_size', 0))")
  _ctx_effective=$(( _ctx_size - 33000 ))
  pct=$(( _ctx_tokens * 100 / _ctx_effective )) 2>/dev/null
  if [[ -n "$pct" && "$pct" -gt 0 ]] 2>/dev/null; then

      # Heatmap colors for positions 0-9 (green → yellow → red)
      # True color RGB values interpolated by position
      heatmap_color() {
        local pos=$1
        local r g b
        if [[ $pos -lt 5 ]]; then
          # Green (0,180,0) → Yellow (220,180,0)
          r=$((pos * 220 / 5))
          g=180
          b=0
        else
          # Yellow (220,180,0) → Red (220,60,0)
          r=220
          g=$((180 - (pos - 5) * 120 / 5))
          b=0
        fi
        printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
      }

      # Build 10-char bar with 40-step precision (4 gradient levels per char)
      steps=$((pct * 40 / 100))
      [[ $steps -gt 40 ]] && steps=40

      full=$((steps / 4))
      partial=$((steps % 4))
      empty=$((10 - full - (partial > 0 ? 1 : 0)))

      # Colors
      dim=$'\033[38;5;238m'
      reset=$'\033[0m'

      # Rounded caps (powerline round separators)
      left_cap=$'\xEE\x82\xB6'   # U+E0B6 round left
      right_cap=$'\xEE\x82\xB4'  # U+E0B4 round right

      # Build bar with per-segment heatmap colors
      bar=""
      pos=0
      for ((i=0; i<full; i++)); do
        bar+="$(heatmap_color $pos)█"
        ((pos++))
      done
      # Partial segment: progressively dimmed based on fill level
      # ▓ (75%) = 80% bright, ▒ (50%) = 55% bright, ░ (25%) = 35% bright
      heatmap_color_partial() {
        local pos=$1 brightness=$2
        local r g b
        if [[ $pos -lt 5 ]]; then
          r=$((pos * 220 / 5 * brightness / 100))
          g=$((180 * brightness / 100))
          b=0
        else
          r=$((220 * brightness / 100))
          g=$(((180 - (pos - 5) * 120 / 5) * brightness / 100))
          b=0
        fi
        printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
      }

      if [[ $partial -gt 0 ]]; then
        dim_pos=$((pos > 0 ? pos - 1 : 0))
        case $partial in
          1) bar+="$(heatmap_color_partial $dim_pos 35)░" ;;
          2) bar+="$(heatmap_color_partial $dim_pos 55)▒" ;;
          3) bar+="$(heatmap_color_partial $dim_pos 80)▓" ;;
        esac
      fi

      # Build track (empty portion) - dim
      track=""
      for ((i=0; i<empty; i++)); do track+="░"; done

      # Left cap color (first segment color or dim)
      if [[ $full -gt 0 || $partial -gt 0 ]]; then
        left="$(heatmap_color 0)${left_cap}"
      else
        left="${dim}${left_cap}"
      fi

      # Right cap - matches last filled segment or dim
      dim_cap=$'\033[38;2;40;40;40m'
      if [[ $empty -eq 0 && $partial -eq 0 ]]; then
        # Full bar: right cap matches last segment (position 9)
        output="${left}${bar}$(heatmap_color 9)${right_cap}${reset}"
      else
        # Partial bar: track dim, cap darker
        output="${left}${bar}${dim}${track}${dim_cap}${right_cap}${reset}"
      fi

      # Percentage colored by last filled position
      last_pos=$((full + (partial > 0 ? 1 : 0) - 1))
      [[ $last_pos -lt 0 ]] && last_pos=0
      pct_color=$(heatmap_color $last_pos)

      segments+=("${output} ${pct_color}${pct}%${reset}")
  fi

  # Add directory at the end (土黄色)
  if [[ -n "$dir_display" ]]; then
    segments+=("$(printf '\033[38;5;136m%s\033[0m' "$dir_display")")
  fi

  # Join with separator
  sep=" \033[2m│\033[0m "
  output=""
  for i in "${!segments[@]}"; do
    [[ $i -gt 0 ]] && output+="$sep"
    output+="${segments[$i]}"
  done
  printf "%b\n" "$output"
}

# Check if we should run in continuous mode for time updates
if [[ "$1" == "--continuous" ]]; then
  # Continuous mode - read input once, then update time every second
  input=$(cat)

  while true; do
    generate_status_line "$input"
    sleep 1
  done
else
  # Single shot mode - for compatibility
  input=$(cat)
  generate_status_line "$input"
fi