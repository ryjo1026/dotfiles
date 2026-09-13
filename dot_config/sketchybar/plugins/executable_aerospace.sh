#!/usr/bin/env bash
# $1 is this item's workspace. $FOCUSED_WORKSPACE comes with the
# aerospace_workspace_change event; on the initial run at bar load it is unset,
# so ask AeroSpace directly instead of leaving every workspace unhighlighted.
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

if [[ "$1" == "$focused" ]]; then
  sketchybar --set "$NAME" background.drawing=on
else
  sketchybar --set "$NAME" background.drawing=off
fi
