# Enable p10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

# homebrew
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

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

# fzf & ripgrep
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# zoxide
eval "$(zoxide init zsh)"

# kubernetes
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
  alias k="kubectl"
  compdef __start_kubectl k

  alias kgp="kubectl get pods"
  alias kgs="kubectl get svc"
  alias kgn="kubectl get nodes"
fi

if command -v helm &>/dev/null; then
  source <(helm completion zsh)
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

alias pc="pre-commit run --all-files"
alias gl="git log"
alias gds="git diff --staged"


[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
