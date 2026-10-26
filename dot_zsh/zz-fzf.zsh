# zz- prefix: must source after keybindings.zsh, whose `^I` binding fzf captures as its plain-TAB fallback.
if command -v fzf &>/dev/null; then
  _cached_eval fzf --zsh
fi
