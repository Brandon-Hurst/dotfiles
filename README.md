# dotfiles

Personal configuration files, structured to mirror `$HOME`.

## Contents

- `.config/ghostty/config` — Ghostty terminal config (zsh, JetBrainsMono Nerd Font, custom warm palette).
- `.config/starship.toml` — Starship prompt config.
- `.zshrc` — zsh config (Oh My Zsh, Starship prompt, aliases, PATH).

## Dependencies

The `.zshrc` expects these to be installed (otherwise the shell won't look/behave the same):

- [Oh My Zsh](https://ohmyz.sh/) at `~/.oh-my-zsh`
- [Starship](https://starship.rs/) prompt (`starship`)
- `zsh-syntax-highlighting` (sourced from `/usr/share/zsh-syntax-highlighting/`) — also colors comments typed at the prompt
- `fzf`
- `bat` (invoked as `batcat` on Debian/Ubuntu)
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/) for Ghostty

## Install on a new machine

```sh
git clone <your-repo-url> ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` (Debian/Ubuntu) installs the dependencies above — apt packages, Oh My
Zsh, and Starship — then symlinks the config files into place (backing up any
existing file to `*.bak`) and sets zsh as the default shell.

Ghostty itself and the Nerd Font are not installed by the script — see the links
above. Afterwards, reload Ghostty (`Ctrl+Shift+,`) or restart it, and open a new shell.
