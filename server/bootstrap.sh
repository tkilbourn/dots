#!/bin/bash
# First-login setup for a cloud dev server (Ubuntu LTS). Run as your own user,
# not root; uses sudo where it needs to. Safe to re-run.
#
#   git clone --recurse-submodules https://github.com/TKilbourn/dots.git ~/dots
#   ~/dots/server/bootstrap.sh
#
# cloud-init.yaml in this directory does exactly that on first boot.

set -euo pipefail

GIT_NAME="Tim Kilbourn"
GIT_EMAIL="tkilbourn@gmail.com"
NVM_VERSION="v0.40.3"
SWAP_SIZE="${SWAP_SIZE:-8G}"

# No needrestart: under cloud-init it restarts cloud-init itself, which kills
# this script mid-run. Reboot afterwards instead.
APT=(sudo env DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1
     apt-get -y -o DPkg::Lock::Timeout=600)

step() { printf '\n==> %s\n' "$*"; }

# --- System (sudo) ----------------------------------------------------------

step "Packages"
"${APT[@]}" update
"${APT[@]}" upgrade
"${APT[@]}" install \
    build-essential git git-lfs zsh vim tmux curl wget ca-certificates gnupg \
    unzip zip rsync jq tree man-db ripgrep fd-find fzf htop btop \
    universal-ctags ccache python3 python3-venv pipx gh earlyoom ufw

step "Kernel settings for VS Code file watching on large trees"
sudo tee /etc/sysctl.d/60-dev.conf >/dev/null <<'EOF'
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1024
EOF
sudo sysctl --system >/dev/null

step "Swap"
if [[ -z "$(swapon --noheadings)" ]]; then
    sudo fallocate -l "$SWAP_SIZE" /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile >/dev/null
    sudo swapon /swapfile
    grep -q '^/swapfile ' /etc/fstab ||
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
else
    echo "already have swap; leaving it"
fi

step "earlyoom (kill the biggest process before the kernel OOM killer locks up)"
sudo systemctl enable --now earlyoom

step "Firewall: SSH only"
sudo ufw allow OpenSSH >/dev/null
sudo ufw --force enable >/dev/null

step "Login shell"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    sudo chsh -s "$(command -v zsh)" "$USER"
fi

# --- User -------------------------------------------------------------------

step "Git identity (setup.sh prompts for it otherwise)"
git config -f ~/.gitconfig_local user.name >/dev/null ||
    git config -f ~/.gitconfig_local user.name "$GIT_NAME"
git config -f ~/.gitconfig_local user.email >/dev/null ||
    git config -f ~/.gitconfig_local user.email "$GIT_EMAIL"

step "Git uses gh's GitHub sign-in (what 'gh auth setup-git' would add)"
# Here and not via setup-git, which writes through the ~/.gitconfig symlink
# into the dots repo.
GH_HELPER_KEY="credential.https://github.com.helper"
if ! git config -f ~/.gitconfig_local --get-all "$GH_HELPER_KEY" |
        grep -q 'gh auth git-credential'; then
    git config -f ~/.gitconfig_local --add "$GH_HELPER_KEY" ""
    git config -f ~/.gitconfig_local --add "$GH_HELPER_KEY" \
        "!$(command -v gh) auth git-credential"
fi

step "Dotfiles"
if [[ ! -d ~/dots/.git ]]; then
    git clone --recurse-submodules https://github.com/TKilbourn/dots.git ~/dots
else
    git -C ~/dots submodule update --init --recursive
fi
bash ~/dots/setup.sh

step "~/.zsh_local (machine-specific, untracked)"
if [[ ! -e ~/.zsh_local ]]; then
    cat > ~/.zsh_local <<'EOF'
# ~/.zsh_local: machine-specific zsh settings for this server.
# Sourced last by ~/.zshrc. Not tracked in the dots repo.

export EDITOR=vim

[[ -d $HOME/bin ]] && path=($HOME/bin $path)
[[ -d $HOME/.local/bin ]] && path=($HOME/.local/bin $path)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
fi

step "fd (Ubuntu names it fdfind)"
mkdir -p ~/.local/bin
ln -sf "$(command -v fdfind)" ~/.local/bin/fd

step "nvm + Node LTS"
if [[ ! -d ~/.nvm ]]; then
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" |
        PROFILE=/dev/null bash
fi
export NVM_DIR="$HOME/.nvm"
# nvm.sh is not written for set -u.
set +u
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'
set -u

step "Claude Code"
if ! command -v claude >/dev/null && [[ ! -x ~/.local/bin/claude ]]; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

step "Login reminder for the steps left to do by hand"
sed "s/@USER@/$USER/" ~/dots/server/motd-todo.sh |
    sudo tee /etc/update-motd.d/99-dev-todo >/dev/null
sudo chmod 755 /etc/update-motd.d/99-dev-todo

cat <<'EOF'

==> Done. Still to do by hand (needs you at the keyboard), also shown at
    each SSH login until done:
    gh auth login        # GitHub sign-in; choose HTTPS
    sudo reboot          # restarts services the upgrade left on old binaries
EOF
