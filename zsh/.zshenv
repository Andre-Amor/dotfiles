export EDITOR="nvim"
export VISUAL="nvim"

# Unique PATH so re-prepending moves a dir to the front instead of duplicating.
# Keeps our dirs ahead of system ones after login files rewrite PATH.
typeset -U path PATH

path=("$HOME/.local/bin" $path)

# rust toolchain
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# homebrew
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
