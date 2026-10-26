if command -v pyenv &>/dev/null || [[ -d "$HOME/.pyenv" ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  _cached_eval pyenv init - --no-rehash zsh
fi
