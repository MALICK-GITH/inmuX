#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT="${1:-$PWD/inmuX.sh}"

if [[ ! -f "$SCRIPT" ]]; then
  printf '[!] inmuX.sh not found: %s\n' "$SCRIPT"
  exit 1
fi

cp -- "$SCRIPT" "$SCRIPT.bak"

awk '
{
  if ($0 ~ /\[\[ "\$url" =~ \^https\?:\/\//) {
    print "  [[ \"$url\" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]{1,5})?([/?#][A-Za-z0-9._~:/?#\\[\\]@!$&()*+,;=%-]*)?$ ]] || return 1"
    next
  }
  print
}
' "$SCRIPT.bak" > "$SCRIPT"

chmod +x "$SCRIPT"

if bash -n "$SCRIPT"; then
  rm -f -- "$SCRIPT.bak"
  printf '[✓] Syntax fixed successfully.\n'
  printf '[✓] File: %s\n' "$SCRIPT"
  printf '[✓] Run: inmux\n'
else
  mv -f -- "$SCRIPT.bak" "$SCRIPT"
  printf '[!] Syntax check still fails. Original file restored.\n'
  exit 1
fi
