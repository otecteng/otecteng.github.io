#/etc/profile.d/rbenv.sh
if [[ ! -d "${HOME}/.rbenv" ]]; then
  export RBENV_ROOT=/usr/local/rbenv'
  export PATH="$RBENV_ROOT/bin:$PATH"'
  eval "$(rbenv init -)"'
fi
