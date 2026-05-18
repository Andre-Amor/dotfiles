#!/usr/bin/env bash
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="mac"
elif [[ -f /etc/os-release ]]; then
  OS="linux"
fi

if [[ "$OS" == "mac" ]]; then
  command -v brew &>/dev/null ||
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew update --quiet
  brew install \
    fzf ripgrep bat eza zoxide tldr git-delta neovim tmux pre-commit ruff \
    kubectl kubectx helm k9s minikube stern argocd kubelogin grpcurl \
    2>/dev/null ||
    brew upgrade \
      fzf ripgrep bat eza zoxide tldr git-delta neovim tmux pre-commit ruff \
      kubectl kubectx helm k9s minikube stern argocd kubelogin grpcurl \
      2>/dev/null || true
else
  command -v brew &>/dev/null || {
    NONINTERACTIVE=1 \
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }

  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  brew update --quiet
  brew install \
    fzf ripgrep bat eza zoxide tldr git-delta neovim tmux pre-commit ruff \
    kubectl kubectx helm k9s minikube stern argocd kubelogin grpcurl \
    2>/dev/null ||
    brew upgrade \
      fzf ripgrep bat eza zoxide tldr git-delta neovim tmux pre-commit ruff \
      kubectl kubectx helm k9s minikube stern argocd kubelogin grpcurl \
      2>/dev/null || true
fi

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  "$HOME/.oh-my-zsh/tools/upgrade.sh" 2>/dev/null || true
else
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# OMZ plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
  name="${plugin##*/}"
  dest="$ZSH_CUSTOM/plugins/$name"
  [[ -d "$dest" ]] && git -C "$dest" pull --quiet ||
    git clone --depth=1 "https://github.com/$plugin" "$dest"
done

# p10k
P10K="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
[[ -d "$P10K" ]] && git -C "$P10K" pull --quiet ||
  git clone --depth=1 https://github.com/romkatv/powerlevel10k "$P10K"

# Make sure the nvim submodule is current
git -C "$DOTFILES" submodule update --init --recursive --remote nvim

mkdir -p "$HOME/.config"
if [[ -e "$HOME/.config/nvim" && ! -L "$HOME/.config/nvim" ]]; then
  rm -rf "$HOME/.config/nvim"
fi
if [[ -L "$HOME/.config/nvim" ]]; then
  rm -f "$HOME/.config/nvim"
fi

ln -sf "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"
ln -sf "$DOTFILES/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES/nvim" "$HOME/.config/nvim"

echo "Installed! Restart terminal or run: source ~/.zshrc"
