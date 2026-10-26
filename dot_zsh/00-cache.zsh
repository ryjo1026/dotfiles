# Reuses a command's init output until its binary changes; never use for output that embeds the current env, such as `fnm env` or `mise activate`.
_cached_eval() {
  local bin=${commands[$1]} cache=${ZDOTDIR:-$HOME}/cache/eval/${(j:_:)@}.zsh
  [[ -n $bin ]] || return 1
  if [[ ! -s $cache || $bin -nt $cache ]]; then
    mkdir -p ${cache:h}
    "$@" >| $cache || { rm -f $cache; return 1; }
  fi
  source $cache
}
