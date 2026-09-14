#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT="${1:-$HOME/inmuX/inmuX.sh}"

if [[ ! -f "$SCRIPT" ]]; then
  printf '[inmuX] File not found: %s\n' "$SCRIPT" >&2
  exit 1
fi

command -v bash >/dev/null 2>&1 || { printf '[inmuX] bash is required.\n' >&2; exit 1; }

printf '[inmuX] Checking syntax: %s\n' "$SCRIPT"
if bash -n "$SCRIPT"; then
  printf '[✓] Syntax OK. No changes were necessary.\n'
else
  printf '[!] Syntax errors found. The file was NOT modified.\n' >&2
  exit 2
fi

if grep -qF "RED=$'\\033[31;1m'" "$SCRIPT"; then
  printf '[✓] ANSI color definitions use real ESC sequences.\n'
else
  printf '[!] ANSI color definitions may still need review.\n'
fi
