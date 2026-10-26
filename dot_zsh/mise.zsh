if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
  # Drops the per-prompt `mise hook-env` fork; env still refreshes on cd, so run `cd .` after `mise use`.
  add-zsh-hook -d precmd _mise_hook_precmd
fi
