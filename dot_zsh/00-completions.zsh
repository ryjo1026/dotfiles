# ----------------------------------------
# Completions
# ----------------------------------------

# Compinit once a day
autoload -Uz compinit
typeset -i updated_at=$(date +'%j' -r ${ZDOTDIR:-$HOME}/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ${ZDOTDIR:-$HOME}/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C
fi
zmodload -i zsh/complist

# Set the completer style for all completion contexts
zstyle ':completion:*' completer \
  _expand \
  _complete \
  _ignored

# select completions with arrow keys
zstyle ':completion:*' menu select
# group results by category
zstyle ':completion:*' group-name ''

# case-insensitive matching (cd doc -> Documents/)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# color the completion list to match ls
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# cache slow completers (brew, apt, pip, ...)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache