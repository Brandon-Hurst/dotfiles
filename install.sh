#!/usr/bin/env bash
#
# Install dotfiles dependencies and link config files into place.
# Targets Debian/Ubuntu (apt). Idempotent — safe to re-run.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }

# --- apt packages ---------------------------------------------------------
info "Installing apt packages (zsh, zsh-syntax-highlighting, fzf, bat)"
sudo apt-get update -qq
sudo apt-get install -y zsh zsh-syntax-highlighting fzf bat git curl

# --- Oh My Zsh ------------------------------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
  info "Oh My Zsh already installed"
else
  info "Installing Oh My Zsh"
  # --unattended: don't change shell or start zsh during install
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- Starship -------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  info "Starship already installed"
else
  info "Installing Starship"
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# --- Link config files ----------------------------------------------------
info "Linking config files into \$HOME"
mkdir -p "$HOME/.config/ghostty"

link() {
  local src="$DOTFILES_DIR/$1" dest="$HOME/$1"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    info "Backing up existing $dest -> $dest.bak"
    mv "$dest" "$dest.bak"
  fi
  ln -sfn "$src" "$dest"
}

link ".zshrc"
link ".config/ghostty/config"
link ".config/starship.toml"

# --- Default shell --------------------------------------------------------
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
  info "Setting zsh as the default shell (may prompt for your password)"
  chsh -s "$(command -v zsh)" || info "Could not change shell automatically; run: chsh -s \$(which zsh)"
fi

info "Done. Notes:"
echo "  - Install Ghostty separately: https://ghostty.org/download"
echo "  - Install JetBrainsMono Nerd Font: https://www.nerdfonts.com/"
echo "  - On Debian/Ubuntu, bat is invoked as 'batcat' (the .zshrc aliases bat=batcat)."
echo "  - Open a new terminal (or run 'exec zsh') to pick up the changes."
