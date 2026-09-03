#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

VERSION="1.0.0"
APP="inmuX"
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
BIN_DIR="$PREFIX_DIR/bin"
INSTALL_PATH="$BIN_DIR/inmux"

if [[ -z "${PREFIX:-}" ]]; then
    printf '[!] This installer is designed for Termux.\n'
    printf '[!] Run it inside Termux where $PREFIX is defined.\n'
    exit 1
fi

if [[ ! -d "$BIN_DIR" ]]; then
    printf '[!] Termux bin directory not found: %s\n' "$BIN_DIR"
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/inmuX.sh"

if [[ ! -f "$SOURCE" ]]; then
    printf '[!] %s not found in %s\n' "inmuX.sh" "$SCRIPT_DIR"
    exit 1
fi

if [[ ! -r "$SOURCE" ]]; then
    printf '[!] Cannot read %s\n' "$SOURCE"
    exit 1
fi

if [[ ! -x "$SOURCE" ]]; then
    chmod +x "$SOURCE"
fi

# Refuse to overwrite an unexpected existing file/symlink.
if [[ -e "$INSTALL_PATH" || -L "$INSTALL_PATH" ]]; then
    if [[ ! -L "$INSTALL_PATH" && ! -f "$INSTALL_PATH" ]]; then
        printf '[!] Refusing to overwrite unexpected object: %s\n' "$INSTALL_PATH"
        exit 1
    fi
fi

TMP="$BIN_DIR/.inmux.tmp.$$"
trap 'rm -f -- "$TMP"' EXIT

cat > "$TMP" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
exec "$SOURCE" "\$@"
EOF

chmod 755 "$TMP"
mv -f -- "$TMP" "$INSTALL_PATH"
trap - EXIT

printf '\n'
printf '========================================\n'
printf '        SOLITAIRE HACK • inmuX\n'
printf '========================================\n'
printf '[✓] Installation complete.\n'
printf '[✓] Command: %s\n' "$INSTALL_PATH"
printf '[✓] Version: %s\n' "$VERSION"
printf '\n'
printf 'Run:  inmux\n'
printf 'Check: command -v inmux\n'
printf '\n'
printf 'Created with assistance from ChatGPT Mobile\n'
