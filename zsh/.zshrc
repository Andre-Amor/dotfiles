# Enable p10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  fzf
  zoxide
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# eza
alias ls="eza --color=never"
alias ll="eza -lh --color=never"
alias la="eza -lha --color=never"
alias lt="eza --tree --level=2 --color=never"

# bat
alias cat="bat --paging=never --plain"

# clear
alias c="clear"

# claude
alias cc="claude"
alias ccr="claude code --resume"

# fzf & ripgrep
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# zoxide
eval "$(zoxide init zsh)"

# Source a command's completion script from a cache file instead of
# regenerating it on every shell start. Compares against the command's
# symlink rather than its target because brew rewrites the symlink on
# upgrade while bottle binaries keep their older build timestamps.
_cached_completion() {
  local cmd="$1"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/${cmd}-completion.zsh"
  zmodload -F zsh/stat b:zstat
  if [[ ! -s "$cache" ]] || (( $(zstat -L +mtime "$(command -v "$cmd")") > $(zstat +mtime "$cache") )); then
    mkdir -p "${cache:h}"
    "$cmd" completion zsh >"$cache.$$" && mv "$cache.$$" "$cache" ||
      { rm -f "$cache.$$"; return 1; }
  fi
  source "$cache"
}

# kubernetes
if command -v kubectl &>/dev/null; then
  _cached_completion kubectl
  alias k="kubectl"
  compdef _kubectl k

  alias kgp="kubectl get pods"
  alias kgs="kubectl get svc"
  alias kgn="kubectl get nodes"
fi

if command -v helm &>/dev/null; then
  _cached_completion helm
fi

alias kctx="kubectx"
alias kns="kubens"

# Autoinstall any git pre-commit hooks when entering any repo
# Runs for every `cd`, should be low overhead/latency though
_precommit_autoinstall() {
  if git rev-parse --git-dir &>/dev/null 2>&1; then
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ -f "$root/.pre-commit-config.yaml" && ! -f "$root/.git/hooks/pre-commit" ]]; then
      echo "pre-commit: installing hooks..."
      pre-commit install --install-hooks
    fi
  fi
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _precommit_autoinstall
_precommit_autoinstall

# Keep Git ahead and behind prompt indicators fresh without blocking `cd`.
typeset -g GIT_AUTOFETCH_TTL_SECONDS=${GIT_AUTOFETCH_TTL_SECONDS:-900}
_git_autofetch_on_chpwd() {
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local root cache_dir safe_root stamp_file last_fetch now
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return
  git -C "$root" rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null || return

  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/git-autofetch"
  mkdir -p "$cache_dir" 2>/dev/null || return

  safe_root="${root//\//_}"
  safe_root="${safe_root//:/_}"
  stamp_file="$cache_dir/${safe_root}.stamp"

  zmodload zsh/datetime
  zmodload -F zsh/stat b:zstat
  now=$EPOCHSECONDS
  last_fetch=0
  [[ ! -f "$stamp_file" ]] || last_fetch=$(zstat +mtime "$stamp_file" 2>/dev/null || echo 0)
  (( now - last_fetch >= GIT_AUTOFETCH_TTL_SECONDS )) || return

  touch "$stamp_file" 2>/dev/null || return
  (
    GIT_TERMINAL_PROMPT=0 git -C "$root" fetch --quiet --prune --no-tags </dev/null ||
      print -u2 "git autofetch failed: $root"
  ) &!
}
add-zsh-hook chpwd _git_autofetch_on_chpwd
_git_autofetch_on_chpwd

alias pc="pre-commit run --all-files"
alias gl="git log"
alias gds="git diff --staged"


[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
