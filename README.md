# inmuX

**SOLITAIRE HACK ⚡ inmuX** — Termux recon, network diagnostics and local reporting toolkit.

> For authorized security testing, diagnostics and learning only.

## Version

`2.0.5`

## Features

- DNS Lookup / Reverse DNS / WHOIS
- GeoIP metadata
- Host and subdomain discovery
- HTTP security headers
- Host + DNS information
- Nmap service scan (top 100 open ports)
- Subnet lookup
- DNS zone-transfer (AXFR) check
- Link extraction
- Local report management

Reports are stored in `~/inmuX-results` with restrictive permissions (`700` directory, `600` files).

## Install

Inside Termux:

```bash
pkg install -y git
bash -c "$(curl -fsSL https://raw.githubusercontent.com/MALICK-GITH/inmuX/main/install.sh)"
```

Manual installation:

```bash
git clone https://github.com/MALICK-GITH/inmuX.git ~/inmuX
cd ~/inmuX
chmod 700 inmuX.sh
./inmuX.sh
```

## Update

```bash
cd ~/inmuX
git pull --ff-only origin main
chmod 700 inmuX.sh install.sh fix_syntax.sh
./inmuX.sh
```

## Dependencies

The installer provides: `git bash curl dnsutils whois nmap grep sed coreutils findutils`.

You can also use menu option **97 — Install/Update Dependencies**.

## Syntax check

```bash
bash ~/inmuX/fix_syntax.sh
```

The checker is non-destructive: it reports syntax problems but does not rewrite the script.

## Security

- Strict host and URL validation.
- User-controlled values are passed as arguments rather than shell-interpolated commands where possible.
- API parameters are URL-encoded.
- Nmap and AXFR require explicit confirmation.
- Local reports use restrictive permissions.
- Use inmuX only on systems and networks you own or are authorized to assess.

## Troubleshooting

If you previously saw literal strings such as `\\033[31;1m`, update to `v2.0.5`. ANSI color variables now use Bash `$'...'` strings, producing real terminal escape sequences.

If a dependency is missing, run option `97` or install it with `pkg install <package>`.

Some online features depend on external services and can fail because of connectivity, DNS, rate limits or service availability; command output is kept in the report when possible.

**SOLITAIRE HACK — RECON • NETWORK • SECURITY**
