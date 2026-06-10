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
else
  command -v brew &>/dev/null || {
    NONINTERACTIVE=1 \
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  }

  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

brew update --quiet
HOMEBREW_BUNDLE_NO_LOCK=1 brew bundle --file="$DOTFILES/Brewfile"

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

# Rust toolchain
command -v cargo &>/dev/null ||
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Claude Code
command -v claude &>/dev/null ||
  curl -fsSL https://claude.ai/install.sh | bash

# Codex
command -v codex &>/dev/null ||
  npm install -g @openai/codex

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
ln -sf "$DOTFILES/zsh/.zprofile" "$HOME/.zprofile"
ln -sf "$DOTFILES/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"
ln -sf "$DOTFILES/nvim" "$HOME/.config/nvim"

if [[ ! -e "$HOME/.gitconfig.identity" ]]; then
  echo "What kind of laptop is this?"
  PS3="Laptop identity: "
  select identity in personal work; do
    case "$identity" in
    personal | work)
      ln -sf "$DOTFILES/git/.gitconfig.$identity" "$HOME/.gitconfig.identity"
      echo "Using Git identity: $identity"
      break
      ;;
    *)
      echo "Please choose 1 or 2."
      ;;
    esac
  done
fi

echo "Installed! Restart terminal or run: \`exec zsh -l\`"
