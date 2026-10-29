#!/usr/bin/env bash
# PostToolUse(Bash) hook: records the checkout this session last ran git in and the PRs it opened, for statusline-command.sh.
command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
sid=$(jq -r '.session_id // empty' <<<"$input")
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$sid" ] || exit 0
# Only commands that produce work move the tracked checkout; read-only git (status, log, diff) in another repo must not.
printf '%s' "$cmd" | grep -qE 'git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+(checkout|switch|commit|push|rebase|cherry-pick|merge)|gh[[:space:]]+(pr[[:space:]]+create|stack)' || exit 0

state="$HOME/.claude/statusline-state"
mkdir -p "$state"
find "$state" -type f -mtime +7 -delete 2>/dev/null

# The hook's cwd is the session's, so a `cd X &&` or `git -C X` inside the command names the checkout it really touched.
target=$(printf '%s' "$cmd" | grep -oE '(^|[;&|(][[:space:]]*)cd[[:space:]]+[^[:space:];&|)]+|git[[:space:]]+-C[[:space:]]+[^[:space:];&|)]+' | head -n1 | awk '{print $NF}')
target=${target//\"/}
target=${target//\'/}
case "$target" in
  "~"*) target="$HOME${target#\~}" ;;
  '$HOME'*) target="$HOME${target#\$HOME}" ;;
esac
[ -n "$target" ] && [ "${target#/}" = "$target" ] && target="$cwd/$target"
[ -z "$target" ] && target=$cwd

if toplevel=$(git -C "$target" --no-optional-locks rev-parse --show-toplevel 2>/dev/null); then
  printf '%s\n' "$toplevel" >"$state/$sid.repo"
fi

case "$cmd" in
  *"gh pr create"*|*"gh stack"*)
    prs="$state/$sid.prs"
    touch "$prs"
    jq -r '.tool_response | tostring' <<<"$input" |
      grep -oE 'https://github\.com/[^/[:space:]]+/[^/[:space:]]+/pull/[0-9]+' |
      while IFS= read -r url; do
        grep -qxF "$url" "$prs" || printf '%s\n' "$url" >>"$prs"
      done
    ;;
esac
exit 0
