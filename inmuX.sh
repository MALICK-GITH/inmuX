#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

readonly VERSION="2.0.3"
readonly APP="inmuX"
readonly OUTDIR="${HOME}/inmuX-results"
readonly TIMEOUT=15

if [[ -t 1 ]]; then
  BOLD='\033[1m'; DIM='\033[2m'; GREEN='\033[32;1m'; YELLOW='\033[33;1m'
  BLUE='\033[34;1m'; RED='\033[31;1m'; CYAN='\033[36;1m'; MAGENTA='\033[35;1m'; RESET='\033[0m'
else
  BOLD=''; DIM=''; GREEN=''; YELLOW=''; BLUE=''; RED=''; CYAN=''; MAGENTA=''; RESET=''
fi

trap 'printf "\n%s[!] Interrupted.%s\n" "$YELLOW" "$RESET"; exit 130' INT

banner() {
  clear 2>/dev/null || true
  printf '%s\n' "$RED"
  cat <<'ASCII'
 ██╗███╗   ██╗███╗   ███╗██╗   ██╗██╗  ██╗
 ██║████╗  ██║████╗ ████║██║   ██║╚██╗██╔╝
 ██║██╔██╗ ██║██╔████╔██║██║   ██║ ╚███╔╝
 ██║██║╚██╗██║██║╚██╔╝██║██║   ██║ ██╔██╗
 ██║██║ ╚████║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
 ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝

        S O L I T A I R E   H A C K
                   ⚡ inmuX ⚡
        RECON • NETWORK • SECURITY

  ┌──────────────────────────────────────────┐
  │  Modern Termux Recon & Diagnostics       │
  │  Secure input • Local reports • APIs     │
  └──────────────────────────────────────────┘

        Created with assistance from ChatGPT Mobile
ASCII
  printf '%s┌──────────────────────────────────────────┐%s\n' "$RED" "$RESET"
  printf '%s│ %s%s v%-6s%s  │  %sAUTHORIZED TESTING ONLY%s │%s\n' "$RED" "$BOLD" "$APP" "$VERSION" "$RED" "$YELLOW" "$RED" "$RESET"
  printf '%s└──────────────────────────────────────────┘%s\n\n' "$RED" "$RESET"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf '%s[!] Missing dependency: %s%s\n' "$YELLOW" "$1" "$RESET"
    return 1
  }
}

install_deps() {
  printf '%s[*] Installing recommended Termux packages...%s\n' "$CYAN" "$RESET"
  pkg update -y
  pkg install -y bash curl dnsutils whois nmap grep sed coreutils
  printf '%s[✓] Dependencies ready.%s\n' "$GREEN" "$RESET"
  sleep 1
}

# Host-only validation for DNS/WHOIS/Nmap. Rejects option injection and unsafe characters.
safe_host() {
  local target="$1"
  [[ -n "$target" ]] || return 1
  [[ "$target" != -* ]] || return 1
  [[ "$target" != *[[:space:]]* ]] || return 1
  [[ "$target" != *'/'* && "$target" != *'?'* && "$target" != *'#'* && "$target" != *'@'* ]] || return 1
  [[ "$target" != *$'\n'* && "$target" != *$'\r'* ]] || return 1
  [[ "$target" =~ ^[A-Za-z0-9][A-Za-z0-9._:-]{0,252}$ ]] || return 1
}

# URL validation for HTTP-only features. No credentials, fragments, query tricks or non-HTTP schemes.
safe_url() {
  local url="$1"
  [[ "$url" == http://* || "$url" == https://* ]] || return 1
  [[ "$url" != *[[:space:]]* ]] || return 1
  [[ "$url" != *$'\n'* && "$url" != *$'\r'* ]] || return 1
  [[ "$url" != *'@'* ]] || return 1
  [[ "$url" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]{1,5})?([/?#][A-Za-z0-9._~:/?#\[\]@!$&'\''()*+,;=%-]*)?$ ]] || return 1
}

ask_host() {
  local target
  read -r -p '╰─> Target (domain/IP): ' target
  safe_host "$target" || {
    printf '%s[!] Invalid host. Use a domain, IPv4 or IPv6 address only.%s\n' "$RED" "$RESET"
    return 1
  }
  TARGET="$target"
}

ask_url() {
  local target url
  read -r -p '╰─> URL (http/https): ' target
  url="$target"
  [[ "$url" == http://* || "$url" == https://* ]] || url="https://$url"
  safe_url "$url" || {
    printf '%s[!] Invalid URL. Only http:// and https:// URLs are accepted.%s\n' "$RED" "$RESET"
    return 1
  }
  TARGET="$url"
}

new_report() {
  mkdir -p "$OUTDIR"
  chmod 700 "$OUTDIR"
  local stamp safe
  stamp="$(date '+%Y%m%d_%H%M%S')"
  safe="$(printf '%s' "$TARGET" | tr -c '[:alnum:]._-' '_')"
  REPORT="$OUTDIR/${stamp}_${safe}_${1}.txt"
  {
    printf 'inmuX v%s\nTarget: %s\nDate: %s\n' "$VERSION" "$TARGET" "$(date -Is)"
    printf '----------------------------------------\n\n'
  } > "$REPORT"
  chmod 600 "$REPORT"
}

run_report() {
  local title="$1"; shift
  printf '%s[*] %s...%s\n' "$CYAN" "$title" "$RESET"
  if "$@" >> "$REPORT" 2>&1; then
    printf '%s[✓] Done%s\n' "$GREEN" "$RESET"
  else
    printf '%s[!] Command returned an error; see report.%s\n' "$YELLOW" "$RESET"
  fi
  printf '\n' >> "$REPORT"
}

finish() {
  printf '%s[✓] Report saved locally:%s %s\n' "$GREEN" "$RESET" "$REPORT"
  read -r -p 'Press Enter to return to menu...' _
}

header() { printf '%s\n### %s\n' "$1" "$(date -Is)"; }

dns_lookup() {
  ask_host || return
  new_report dns
  run_report 'DNS records' bash -c 'header "DNS"; dig +noall +answer -- "$1"' _ "$TARGET"
  finish
}

reverse_dns() {
  ask_host || return
  new_report reverse-dns
  run_report 'Reverse DNS' bash -c 'header "Reverse DNS"; dig -x -- "$1" +noall +answer' _ "$TARGET"
  finish
}

whois_lookup() {
  ask_host || return
  new_report whois
  run_report 'WHOIS' whois "$TARGET"
  finish
}

geoip_lookup() {
  ask_host || return
  new_report geoip
  run_report 'GeoIP metadata' bash -c 'header "GeoIP"; curl --fail --silent --show-error --max-time "$2" --get --data-urlencode "ip=$1" "https://ipwho.is/"' _ "$TARGET" "$TIMEOUT"
  finish
}

host_finder() {
  ask_host || return
  new_report hostsearch
  run_report 'Subdomain/host discovery' bash -c 'header "Host discovery"; curl --fail --silent --show-error --max-time "$2" --get --data-urlencode "q=$1" "https://api.hackertarget.com/hostsearch/"' _ "$TARGET" "$TIMEOUT"
  finish
}

http_headers() {
  ask_url || return
  new_report headers
  run_report 'HTTP security headers' bash -c 'header "HTTP headers"; curl --fail --silent --show-error --head --max-time "$2" --connect-timeout 7 -- "$1"' _ "$TARGET" "$TIMEOUT"
  finish
}

host_dns() {
  ask_host || return
  new_report host-dns
  run_report 'Host/DNS information' bash -c 'header "Host"; { getent hosts "$1" || true; }; printf "\nDNS:\n"; dig -- "$1" +noall +answer' _ "$TARGET"
  finish
}

port_scan() {
  ask_host || return
  new_report nmap
  if ! need_cmd nmap; then
    printf '%sUse option 97 first to install dependencies.%s\n' "$YELLOW" "$RESET"
    read -r -p 'Press Enter...' _
    return
  fi
  printf '%s[!] Run port scans only against systems you own or are authorized to test.%s\n' "$YELLOW" "$RESET"
  read -r -p 'Continue? (y/N): ' confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || return
  run_report 'Nmap service scan' nmap -sV --top-ports 100 --open --host-timeout 60s -- "$TARGET"
  finish
}

subnet_lookup() {
  ask_host || return
  new_report subnet
  run_report 'Subnet calculation' bash -c 'header "Subnet"; curl --fail --silent --show-error --max-time "$2" --get --data-urlencode "q=$1" "https://api.hackertarget.com/subnetcalc/"' _ "$TARGET" "$TIMEOUT"
  finish
}

zone_transfer() {
  ask_host || return
  new_report axfr
  printf '%s[!] AXFR should only be tested on DNS zones you administer or have permission to assess.%s\n' "$YELLOW" "$RESET"
  read -r -p 'Continue? (y/N): ' confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || return
  run_report 'DNS zone transfer check' bash -c 'header "AXFR"; servers=$(dig +short NS -- "$1"); while IFS= read -r ns; do [[ -n "$ns" ]] || continue; printf "== %s ==\n" "$ns"; dig +time=3 +tries=1 AXFR "$1" "@$ns"; done <<< "$servers"' _ "$TARGET"
  finish
}

extract_links() {
  ask_url || return
  new_report links
  run_report 'Extracting links' bash -c 'header "Links"; curl --fail --silent --show-error --max-time "$2" -- "$1" | grep -Eoi "https?://[^\"[:space:]<>]+" | sed "s/[),.;]$//" | sort -u' _ "$TARGET" "$TIMEOUT"
  finish
}

view_reports() {
  banner
  mkdir -p "$OUTDIR"
  chmod 700 "$OUTDIR"
  mapfile -t files < <(find "$OUTDIR" -maxdepth 1 -type f -printf '%f\n' | sort -r)
  ((${#files[@]})) || {
    printf '%sNo reports yet.%s\n' "$YELLOW" "$RESET"
    read -r -p 'Press Enter...' _
    return
  }
  printf '%sSaved reports:%s\n\n' "$YELLOW" "$RESET"
  printf '%3s  %s\n' '#' 'FILE'
  local i=1 f
  for f in "${files[@]}"; do
    printf '%3d  %s\n' "$i" "$f"
    ((i++))
  done
  printf '\n'
  read -r -p 'Number (or Enter to return): ' choice
  [[ "$choice" =~ ^[0-9]+$ ]] || return
  ((choice >= 1 && choice <= ${#files[@]})) || {
    printf '%sInvalid choice.%s\n' "$RED" "$RESET"
    sleep 1
    return
  }
  less -R -- "$OUTDIR/${files[choice-1]}" 2>/dev/null || cat -- "$OUTDIR/${files[choice-1]}"
}

delete_report() {
  banner
  mkdir -p "$OUTDIR"
  chmod 700 "$OUTDIR"
  mapfile -t files < <(find "$OUTDIR" -maxdepth 1 -type f -printf '%f\n' | sort -r)
  ((${#files[@]})) || {
    printf '%sNo reports.%s\n' "$YELLOW" "$RESET"
    sleep 1
    return
  }
  local i=1 f
  for f in "${files[@]}"; do
    printf '%3d  %s\n' "$i" "$f"
    ((i++))
  done
  read -r -p 'Number to delete (or Enter to return): ' choice
  [[ "$choice" =~ ^[0-9]+$ ]] || return
  ((choice >= 1 && choice <= ${#files[@]})) || return
  rm -f -- "$OUTDIR/${files[choice-1]}"
  printf '%s[✓] Deleted.%s\n' "$GREEN" "$RESET"
  sleep 1
}

delete_all() {
  banner
  printf '%sThis deletes every local inmuX report.%s\n' "$RED" "$RESET"
  read -r -p 'Type DELETE to confirm: ' confirm
  [[ "$confirm" == 'DELETE' ]] || { printf 'Cancelled.\n'; sleep 1; return; }
  [[ "$OUTDIR" == "$HOME/inmuX-results" && -n "$HOME" ]] || { printf '%s[!] Refusing unsafe delete path.%s\n' "$RED" "$RESET"; sleep 1; return; }
  rm -rf -- "$OUTDIR"
  printf '%s[✓] All reports deleted.%s\n' "$GREEN" "$RESET"
  sleep 1
}

about() {
  banner
  printf '%sVersion:%s %s\n' "$CYAN" "$RESET" "$VERSION"
  printf '%sEngine:%s Bash + native Termux tools + HTTPS APIs\n' "$CYAN" "$RESET"
  printf '%sReports:%s %s (permissions 700/600)\n\n' "$CYAN" "$RESET" "$OUTDIR"
  printf '%sSecurity hardening:%s strict host/URL validation, option-injection protection, encoded API parameters and protected reports.\n\n' "$GREEN" "$RESET"
  printf '%sBuilt for authorized security testing, diagnostics and learning.%s\n' "$YELLOW" "$RESET"
  read -r -p 'Press Enter...' _
}

menu() {
  while true; do
    banner
    cat <<EOF
${RED}  RECON & DISCOVERY${RESET}
${BLUE} 1${RESET}  DNS Lookup
${BLUE} 2${RESET}  Reverse DNS
${BLUE} 3${RESET}  WHOIS
${BLUE} 4${RESET}  GeoIP
${BLUE} 5${RESET}  Host/Subdomain Finder

${GREEN}  NETWORK & WEB${RESET}
${GREEN} 6${RESET}  HTTP Security Headers
${GREEN} 7${RESET}  Host + DNS
${GREEN} 8${RESET}  Port Scanner (Nmap)
${GREEN} 9${RESET}  Subnet Lookup
${GREEN}10${RESET}  DNS Zone Transfer Check
${GREEN}11${RESET}  Extract Links

${CYAN}  REPORTS${RESET}
${CYAN}12${RESET}  View Reports
${CYAN}13${RESET}  Delete Report
${CYAN}14${RESET}  Delete All Reports

${MAGENTA}97${RESET}  Install/Update Dependencies
${MAGENTA}98${RESET}  About / Security
${RED}00${RESET}  Exit
EOF
    printf '\n%s╰─>~# %s%s' "$BOLD" "$RESET" "$RESET"
    read -r choice
    case "$choice" in
      1) dns_lookup;; 2) reverse_dns;; 3) whois_lookup;; 4) geoip_lookup;;
      5) host_finder;; 6) http_headers;; 7) host_dns;; 8) port_scan;;
      9) subnet_lookup;; 10) zone_transfer;; 11) extract_links;; 12) view_reports;;
      13) delete_report;; 14) delete_all;; 97) install_deps;; 98) about;;
      00) printf 'À bientôt !\n'; exit 0;;
      *) printf '%sOption invalide.%s\n' "$RED" "$RESET"; sleep 1;;
    esac
  done
}

menu
