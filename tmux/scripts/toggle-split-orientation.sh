#!/usr/bin/env bash
# Flip the orientation of just the current pane and its sibling, leaving the
# rest of the window's layout alone.
#
# Two panes are siblings when they tile a rectangle exactly: same width and
# column and vertically adjacent (stacked), or same height and row and
# horizontally adjacent (side by side). The +1 accounts for the divider line.
set -eu

read -r cur < <(tmux display-message -p '#{pane_id}')
active=$(tmux display-message -p '#{pane_left} #{pane_top} #{pane_width} #{pane_height}')
read -r ax ay aw ah <<<"$active"

while read -r id x y w h; do
  [ "$id" = "$cur" ] && continue
  if [ "$x" = "$ax" ] && [ "$w" = "$aw" ]; then
    # stacked pair -> make it side by side; keep the upper pane on the left
    if [ "$y" -eq $((ay + ah + 1)) ]; then exec tmux join-pane -h -b -s "$cur" -t "$id"; fi
    if [ "$ay" -eq $((y + h + 1)) ]; then exec tmux join-pane -h -s "$cur" -t "$id"; fi
  fi
  if [ "$y" = "$ay" ] && [ "$h" = "$ah" ]; then
    # side-by-side pair -> stack it; keep the left pane on top
    if [ "$x" -eq $((ax + aw + 1)) ]; then exec tmux join-pane -v -b -s "$cur" -t "$id"; fi
    if [ "$ax" -eq $((x + w + 1)) ]; then exec tmux join-pane -v -s "$cur" -t "$id"; fi
  fi
done < <(tmux list-panes -F '#{pane_id} #{pane_left} #{pane_top} #{pane_width} #{pane_height}')

tmux display-message 'no sibling pane to flip'
