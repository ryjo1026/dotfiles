#!/usr/bin/env bash
# Claude Code status line: model + cwd + git branch (dirty marker), then a context-remaining bar on its own line.
# Reads status line JSON from stdin. Degrades gracefully: no jq -> regex fallback, no git repo -> omit branch, no context field -> omit ctx.

input=$(cat)

# Rosé Pine (main) truecolor palette, matching the Ghostty theme.
rgb() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
C_RESET=$'\033[0m'
C_LOVE=$(rgb 235 111 146)
C_GOLD=$(rgb 246 193 119)
C_ROSE=$(rgb 235 188 186)
C_FOAM=$(rgb 156 207 216)
C_IRIS=$(rgb 196 167 231)
C_SUBTLE=$(rgb 144 140 170)
C_MUTED=$(rgb 110 106 134)
C_HL_MED=$(rgb 64 61 82)

C_MODEL=$C_IRIS
C_DIR=$C_FOAM
C_GIT_CLEAN=$C_ROSE
C_SEP=$C_MUTED

# Powerline glyphs from ~/.p10k.zsh, as UTF-8 bytes because macOS bash 3.2 lacks $'\u…'.
GLYPH_BRANCH=$(printf '\xee\x82\xa0')
GLYPH_SUBSEP=$(printf '\xee\x82\xb1')

# Best-effort JSON scalar extraction when jq isn't installed. First match only, string/number values only.
json_str() { printf '%s' "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n1 | sed -E 's/.*:[[:space:]]*"//; s/"$//'; }
json_num() { printf '%s' "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9.]*" | head -n1 | sed -E 's/.*://'; }

if command -v jq >/dev/null 2>&1; then
  model_name=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
  cwd=$(printf '%s' "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // empty')
  ctx_remaining=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // empty')
else
  model_name=$(json_str display_name)
  cwd=$(json_str project_dir)
  [ -z "$cwd" ] && cwd=$(json_str current_dir)
  ctx_remaining=$(json_num remaining_percentage)
fi

[ -z "$cwd" ] && cwd="$PWD"

# Shorten "Claude Opus 4.5" -> "opus-4.5".
short_model=$(printf '%s' "$model_name" | sed -E 's/^Claude[[:space:]]+//I' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
[ -z "$short_model" ] && short_model="claude"

# cwd is the session's launch dir, so this stays fixed as the shell cds around.
toplevel=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
if [ -n "$toplevel" ]; then
  parent=$(basename "$(dirname "$toplevel")")
  case "$parent" in
    *.worktrees) dir_display="${parent}/$(basename "$toplevel")" ;;
    *) dir_display=$(basename "$toplevel") ;;
  esac
elif [ "$cwd" = "$HOME" ]; then
  dir_display="~"
elif [ "${cwd#"$HOME"/}" != "$cwd" ]; then
  dir_display="~${cwd#"$HOME"}"
else
  dir_display="$cwd"
fi

segments=("${C_MODEL}${short_model}${C_RESET}" "${C_DIR}${dir_display}${C_RESET}")

# Git branch + p10k-style status (⇣behind ⇡ahead +staged !unstaged ?untracked); omit outside a repo. Skip optional locks (read-only, avoid lock contention).
if status_v2=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null); then
  branch="" ahead=0 behind=0 staged=0 unstaged=0 untracked=0
  while IFS= read -r line; do
    case "$line" in
      "# branch.head "*) branch=${line#"# branch.head "} ;;
      "# branch.oid "*) oid=${line#"# branch.oid "} ;;
      "# branch.ab "*)
        read -r _ _ a b <<<"$line"
        ahead=${a#+} behind=${b#-} ;;
      "? "*) untracked=$((untracked + 1)) ;;
      [12u]" "*)
        xy=${line:2:2}
        [ "${xy:0:1}" != "." ] && staged=$((staged + 1))
        [ "${xy:1:1}" != "." ] && unstaged=$((unstaged + 1)) ;;
    esac
  done <<<"$status_v2"
  [ "$branch" = "(detached)" ] && branch="@${oid:0:8}"

  if [ -n "$branch" ]; then
    git_seg="${C_GIT_CLEAN}${GLYPH_BRANCH} ${branch}"
    [ "$behind" -gt 0 ] && git_seg+=" ${C_SUBTLE}⇣${behind}"
    [ "$ahead" -gt 0 ] && git_seg+=" ${C_SUBTLE}⇡${ahead}"
    [ "$staged" -gt 0 ] && git_seg+=" ${C_FOAM}+${staged}"
    [ "$unstaged" -gt 0 ] && git_seg+=" ${C_GOLD}!${unstaged}"
    [ "$untracked" -gt 0 ] && git_seg+=" ${C_IRIS}?${untracked}"
    segments+=("${git_seg}${C_RESET}")
  fi
fi

# Context remaining as a burn-down bar + %, omit if the field isn't present in the payload.
if [ -n "$ctx_remaining" ] && [ "$ctx_remaining" != "null" ]; then
  ctx_int=$(printf '%.0f' "$ctx_remaining" 2>/dev/null || printf '%s' "$ctx_remaining")
  case "$ctx_int" in ''|*[!0-9]*) ctx_int=0 ;; esac
  [ "$ctx_int" -gt 100 ] && ctx_int=100
  if [ "$ctx_int" -le 20 ]; then
    c_bar=$C_LOVE
  elif [ "$ctx_int" -le 50 ]; then
    c_bar=$C_GOLD
  else
    c_bar=$C_FOAM
  fi
  bar_width=20
  filled=$(( (ctx_int * bar_width + 50) / 100 ))
  fill="" track=""
  for ((i = 0; i < bar_width; i++)); do
    if [ "$i" -lt "$filled" ]; then fill+="━"; else track+="━"; fi
  done
  ctx_line="${c_bar}${fill}${C_HL_MED}${track} ${c_bar}${ctx_int}%${C_SUBTLE} context left${C_RESET}"
fi

sep="${C_SEP} ${GLYPH_SUBSEP} ${C_RESET}"
out=""
for seg in "${segments[@]}"; do
  if [ -z "$out" ]; then
    out="$seg"
  else
    out="${out}${sep}${seg}"
  fi
done

printf '%s\n' "$out"
[ -n "$ctx_line" ] && printf '%s\n' "$ctx_line"
exit 0
