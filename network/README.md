# sniX Network

**sniX** is the network-discovery module for the new inmuX project.

It focuses on **SNI/TLS visibility** for authorized diagnostics:

- TLS SNI probing
- certificate CN/SAN discovery
- TLS version and cipher
- ALPN (`h2` / `http/1.1`)
- issuer and certificate validity dates
- reverse DNS enrichment
- bounded CIDR discovery (maximum 256 addresses)
- concurrent probes with a hard worker ceiling
- JSON reports

## Usage

```bash
python3 network/sniX.py example.com
python3 network/sniX.py example.com -p 443,8443
python3 network/sniX.py 192.168.1.1
python3 network/sniX.py 192.168.1.0/24 -p 443 -w 16
python3 network/sniX.py -f targets.txt -o report.json
```

`targets.txt` contains one hostname, IP address, or CIDR per line. Lines beginning with `#` are ignored.

## Safety boundary

Use sniX only on systems and networks you own or have explicit permission to assess. The module intentionally does **not** implement exploitation, credential attacks, stealth/evasion, or unrestricted Internet-wide scanning.

## Next modules planned

- passive PCAP SNI extraction
- DNS intelligence
- HTTP/TLS fingerprinting
- local-network inventory
- structured reports
- interactive terminal UI
