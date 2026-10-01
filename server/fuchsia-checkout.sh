#!/bin/bash
# Check out fuchsia.git on a dev server, following
# https://fuchsia.dev/fuchsia-src/get-started/get_fuchsia_source
# Run by hand; bootstrap.sh does not run it. Safe to re-run until the
# download starts; after that, use "jiri update" in the checkout instead.
#
#   tmux new -s fuchsia ~/dots/server/fuchsia-checkout.sh [PARENT_DIR]
#
# The checkout goes to PARENT_DIR/fuchsia (default: ~/fuchsia). It takes a
# while; run it inside tmux so a dropped SSH connection does not kill it.

set -euo pipefail

PARENT_DIR="$(realpath "${1:-$HOME}")"
FUCHSIA_DIR="$PARENT_DIR/fuchsia"
# 2 GB for the source plus 80-90 GB for a build, per fuchsia.dev.
MIN_FREE_GB=100

step() { printf '\n==> %s\n' "$*"; }
die() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

if [[ -e "$FUCHSIA_DIR" ]]; then
    die "$FUCHSIA_DIR already exists. To update it: cd $FUCHSIA_DIR && jiri update"
fi

if [[ -z "${TMUX:-}${STY:-}" && -t 0 ]]; then
    echo "Not running inside tmux or screen: if SSH drops, the download dies."
    read -r -p "Continue anyway? [y/N] " answer
    [[ "$answer" == [yY]* ]] || exit 1
fi

step "Disk space"
free_gb=$(df -BG --output=avail "$PARENT_DIR" | tail -1 | tr -dc 0-9)
echo "$free_gb GB free in $PARENT_DIR"
(( free_gb >= MIN_FREE_GB )) ||
    die "need at least $MIN_FREE_GB GB free (source + one build)"

step "1. Prerequisite packages (curl, file, git >= 2.31, unzip)"
sudo env DEBIAN_FRONTEND=noninteractive NEEDRESTART_SUSPEND=1 \
    apt-get install -y -o DPkg::Lock::Timeout=600 curl file git unzip
git_version=$(git --version | awk '{print $3}')
if [[ "$(printf '%s\n' 2.31 "$git_version" | sort -V | head -1)" != 2.31 ]]; then
    die "git $git_version is older than 2.31"
fi

if [[ -e /dev/kvm ]]; then
    step "KVM is available: adding $USER to the kvm group (for the emulator)"
    sudo usermod -a -G kvm "$USER"
else
    step "No /dev/kvm on this server: the emulator would run without acceleration"
fi

step "2. Preflight check (ffx platform preflight)"
if [[ "$(uname -m)" == x86_64 ]]; then
    preflight_dir=$(mktemp -d)
    curl -sSfo "$preflight_dir/ffx-linux-x64" \
        https://storage.googleapis.com/fuchsia-ffx/ffx-linux-x64
    chmod +x "$preflight_dir/ffx-linux-x64"
    # Its findings are advice; report them but carry on.
    "$preflight_dir/ffx-linux-x64" platform preflight ||
        echo "(preflight reported problems; see above)"
    rm -rf "$preflight_dir"
else
    echo "skipped: preflight only supports x64"
fi

step "3. Download the source into $FUCHSIA_DIR"
cd "$PARENT_DIR"
curl -sSf "https://fuchsia.googlesource.com/fuchsia/+/HEAD/scripts/bootstrap?format=TEXT" |
    base64 --decode > bootstrap.sh
# The Fuchsia bootstrap deletes bootstrap.sh itself when it exits.
bash bootstrap.sh

step "4. Environment variables (in ~/.zsh_local, where this setup keeps them)"
if ! grep -qs 'jiri_root/bin' ~/.zsh_local; then
    cat >> ~/.zsh_local <<EOF

# Fuchsia (added by dots/server/fuchsia-checkout.sh): jiri, fx and fx-env.sh.
# Note fx-env.sh defines an fd() function, which hides the fd file finder;
# use fdfind for that.
if [[ -d $FUCHSIA_DIR/.jiri_root/bin ]]; then
    path=($FUCHSIA_DIR/.jiri_root/bin \$path)
    source $FUCHSIA_DIR/scripts/fx-env.sh
fi
EOF
fi

step "Verify: jiri help, fx help"
(
    cd "$FUCHSIA_DIR"
    export PATH="$FUCHSIA_DIR/.jiri_root/bin:$PATH"
    jiri help >/dev/null && echo "jiri: ok"
    fx help >/dev/null && echo "fx: ok"
)

cat <<EOF

==> Done: Fuchsia source in $FUCHSIA_DIR.
    Open a new shell (or: source ~/.zsh_local) to get jiri and fx on PATH.

    Not done here, on purpose:
    - fx setup-ufw (step 5, optional): opens firewall ports for emulator and
      device traffic; on a public server keep the firewall SSH-only.
    - Emulator tap networking: only if you run the emulator here, see
      https://fuchsia.dev/fuchsia-src/get-started/get_fuchsia_source#configure-emulator-networking
    - To upload changes to Gerrit, set up ~/.gitcookies from
      https://fuchsia-review.googlesource.com (Settings > HTTP credentials).
    Next: https://fuchsia.dev/fuchsia-src/get-started/build_fuchsia
EOF
