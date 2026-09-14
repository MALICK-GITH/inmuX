# inmuX

**SOLITAIRE HACK ⚡ inmuX** — Termux recon, network diagnostics and local reporting toolkit.

> For authorized security testing, diagnostics and learning only.

## Current version

`2.0.5`

## Features

### Recon & discovery
- DNS lookup
- Reverse DNS
- WHOIS
- GeoIP metadata
- Host/subdomain discovery

### Network & web
- HTTP response/security headers
- Host + DNS information
- Nmap service scan (top 100 open ports)
- Subnet lookup
- DNS zone-transfer (AXFR) check
- Link extraction

### Reports
- Reports are saved locally in `~/inmuX-results`
- Directory permissions: `700`
- Report permissions: `600`
- View, delete one, or delete all reports with explicit confirmation

## Install

Inside Termux:

```bash
pkg install -y git
bash -c "$(curl -fsSL https://raw.githubusercontent.com/MALICK-GITH/inmuX/main/install.sh)"
```

Or clone manually:

```bash
git clone https://github.com/MALICK-GITH/inmuX.git ~/inmuX
cd ~/inmuX
chmod 700 inmuX.sh
./inmuX.sh
```

## Update

For an existing installation:

```bash
cd ~/inmuX
git pull --ff-only origin main
chmod 700 inmuX.sh install.sh fix_syntax.sh
./inmuX.sh
```

## Dependencies

The installer provides the recommended Termux packages:

`bash curl dnsutils whois nmap grep sed coreutils findutils git`

You can also use menu option **97 — Install/Update Dependencies**.

## Syntax check

The checker is non-destructive:

```bash
bash ~/inmuX/fix_syntax.sh
```

Or provide another script:

```bash
bash ~/inmuX/fix_syntax.sh /path/to/script.sh
```

## Security notes

- Host and URL inputs are validated before network commands.
- User-controlled values are passed as arguments instead of being interpolated into shell commands where possible.
- API query parameters are URL-encoded.
- Nmap and AXFR operations require explicit confirmation.
- Reports are stored with restrictive permissions.
- Do not use the tool against systems, domains or networks without authorization.

## Troubleshooting

### Colors appear as `\\033[...m`

Update to `v2.0.5`. The ANSI variables now use Bash `$'...'` strings so Termux receives real escape characters.

### A dependency is missing

Run menu option `97`, or install the package manually with `pkg install <package>`.

### A network API fails

Some features depend on external services and can fail because of DNS, connectivity, rate limits or service availability. The command result is preserved in the local report when possible.

## Project

Repository: https://github.com/MALICK-GITH/inmuX

**SOLITAIRE HACK — RECON • NETWORK • SECURITY**
