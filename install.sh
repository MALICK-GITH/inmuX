#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

readonly APP="inmuX"
readonly VERSION="2.0.5"
readonly REPO_URL="https://github.com/MALICK-GITH/inmuX.git"
readonly INSTALL_DIR="$HOME/inmuX"
readonly ENTRYPOINT="$INSTALL_DIR/inmuX.sh"

log() { printf '[inmuX] %s\n' "$*"; }
fail() { printf '[inmuX] ERROR: %s\n' "$*" >&2; exit 1; }

command -v pkg >/dev/null 2>&1 || fail 'This installer must be run inside Termux.'

log "Installing Termux prerequisites..."
pkg update -y
pkg install -y git bash curl dnsutils whois nmap grep sed coreutils findutils

if [[ -d "$INSTALL_DIR/.git" ]]; then
  log "Updating existing installation..."
  git -C "$INSTALL_DIR" fetch --depth=1 origin main
  git -C "$INSTALL_DIR" reset --hard origin/main
else
  log "Cloning $APP..."
  rm -rf -- "$INSTALL_DIR"
  git clone --depth=1 --branch main "$REPO_URL" "$INSTALL_DIR"
fi

[[ -f "$ENTRYPOINT" ]] || fail "Missing $ENTRYPOINT after installation."
chmod 700 "$ENTRYPOINT"

mkdir -p "$HOME/inmuX-results"
chmod 700 "$HOME/inmuX-results"

log "Installed $APP v$VERSION"
log "Launch with: $ENTRYPOINT"
log "Or: cd ~/inmuX && ./inmuX.sh"
