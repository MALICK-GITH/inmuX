#!/usr/bin/env python3
"""
sniX Network — SNI/TLS network discovery utility.

AUTHORIZED TESTING ONLY.

Features:
- TLS SNI probing for hostnames/IPs
- Certificate CN/SAN extraction
- TLS version and ALPN detection
- Certificate issuer / validity information
- Reverse DNS enrichment
- Bounded CIDR discovery (max /24)
- Concurrent probing with a conservative worker limit
- JSON report export

No exploit, brute-force, stealth, evasion, or credential functionality is included.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import ipaddress
import json
import socket
import ssl
import sys
import time
from datetime import datetime, timezone
from typing import Iterable

DEFAULT_PORTS = (443, 8443)
MAX_WORKERS = 32
MAX_CIDR_HOSTS = 256


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def clean_name(name: str) -> str:
    return name.strip().rstrip(".")


def reverse_dns(ip: str) -> str | None:
    try:
        return clean_name(socket.gethostbyaddr(ip)[0])
    except (socket.herror, socket.gaierror, OSError):
        return None


def cert_names(cert: dict) -> tuple[list[str], list[str]]:
    dns_names: list[str] = []
    ips: list[str] = []
    for kind, value in cert.get("subjectAltName", ()):
        if kind == "DNS":
            dns_names.append(clean_name(value))
        elif kind == "IP Address":
            ips.append(value)
    return sorted(set(dns_names)), sorted(set(ips))


def probe(target: str, port: int, timeout: float) -> dict:
    started = time.monotonic()
    result = {
        "target": target,
        "port": port,
        "ok": False,
        "ip": None,
        "reverse_dns": None,
        "tls_version": None,
        "cipher": None,
        "alpn": None,
        "sni": target,
        "certificate": None,
        "error": None,
        "latency_ms": None,
    }

    try:
        addr = socket.getaddrinfo(target, port, type=socket.SOCK_STREAM)[0][4]
        ip = addr[0]
        result["ip"] = ip
        result["reverse_dns"] = reverse_dns(ip)

        context = ssl.create_default_context()
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        context.set_alpn_protocols(["h2", "http/1.1"])

        with socket.create_connection((ip, port), timeout=timeout) as raw:
            with context.wrap_socket(raw, server_hostname=target) as tls:
                cert = tls.getpeercert()
                dns_names, ip_names = cert_names(cert)
                subject = cert.get("subject", ())
                issuer = cert.get("issuer", ())

                def dn_value(parts):
                    for group in parts:
                        for key, value in group:
                            if key == "commonName":
                                return value
                    return None

                result.update({
                    "ok": True,
                    "tls_version": tls.version(),
                    "cipher": tls.cipher()[0] if tls.cipher() else None,
                    "alpn": tls.selected_alpn_protocol(),
                    "certificate": {
                        "common_name": dn_value(subject),
                        "issuer": dn_value(issuer),
                        "dns_names": dns_names,
                        "ip_names": ip_names,
                        "not_before": cert.get("notBefore"),
                        "not_after": cert.get("notAfter"),
                    },
                })
    except ssl.SSLError as exc:
        result["error"] = f"TLS: {exc}"
    except (socket.timeout, TimeoutError):
        result["error"] = "timeout"
    except (ConnectionRefusedError, ConnectionResetError, OSError) as exc:
        result["error"] = str(exc)
    except Exception as exc:  # defensive boundary for CLI use
        result["error"] = f"unexpected: {exc}"
    finally:
        result["latency_ms"] = round((time.monotonic() - started) * 1000, 1)

    return result


def expand_targets(raw_targets: Iterable[str]) -> list[str]:
    targets: list[str] = []
    seen: set[str] = set()
    for raw in raw_targets:
        value = raw.strip()
        if not value:
            continue
        try:
            net = ipaddress.ip_network(value, strict=False)
            if net.num_addresses > MAX_CIDR_HOSTS:
                raise ValueError(f"CIDR too large ({net.num_addresses} addresses; max {MAX_CIDR_HOSTS})")
            values = [str(ip) for ip in net.hosts()] if net.num_addresses > 2 else [str(ip) for ip in net]
        except ValueError:
            values = [value]
        for item in values:
            if item not in seen:
                seen.add(item)
                targets.append(item)
    return targets


def parse_ports(value: str) -> list[int]:
    ports: list[int] = []
    for part in value.split(","):
        p = int(part.strip())
        if not 1 <= p <= 65535:
            raise ValueError(f"invalid port: {p}")
        if p not in ports:
            ports.append(p)
    return ports


def print_result(r: dict) -> None:
    prefix = "[+]" if r["ok"] else "[-]"
    endpoint = f"{r['target']}:{r['port']}"
    if not r["ok"]:
        print(f"{prefix} {endpoint}  {r['error']}")
        return

    cert = r["certificate"] or {}
    names = cert.get("dns_names", [])
    print(
        f"{prefix} {endpoint} -> {r['ip']}  "
        f"{r['tls_version']}  ALPN={r['alpn'] or '-'}  "
        f"CN={cert.get('common_name') or '-'}"
    )
    if names:
        print("    SAN: " + ", ".join(names[:20]) + (" ..." if len(names) > 20 else ""))
    if r.get("reverse_dns"):
        print(f"    PTR: {r['reverse_dns']}")


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="sniX",
        description="Fast, bounded TLS/SNI discovery for authorized network diagnostics.",
    )
    parser.add_argument("targets", nargs="*", help="hostnames, IPs, or CIDRs (max /24)")
    parser.add_argument("-f", "--file", help="file containing one target per line")
    parser.add_argument("-p", "--ports", default="443,8443", help="comma-separated TLS ports")
    parser.add_argument("-t", "--timeout", type=float, default=3.0, help="socket timeout in seconds")
    parser.add_argument("-w", "--workers", type=int, default=12, help="concurrent probes (max 32)")
    parser.add_argument("-o", "--output", help="write full results to JSON")
    parser.add_argument("--version", action="version", version="sniX 1.0.0")
    args = parser.parse_args()

    if args.file:
        try:
            with open(args.file, "r", encoding="utf-8") as fh:
                args.targets.extend(line.split("#", 1)[0].strip() for line in fh)
        except OSError as exc:
            print(f"[!] cannot read target file: {exc}", file=sys.stderr)
            return 2

    if not args.targets:
        parser.error("provide at least one target or --file")
    if args.timeout <= 0:
        parser.error("--timeout must be > 0")
    if not 1 <= args.workers <= MAX_WORKERS:
        parser.error(f"--workers must be between 1 and {MAX_WORKERS}")

    try:
        ports = parse_ports(args.ports)
        targets = expand_targets(args.targets)
    except ValueError as exc:
        parser.error(str(exc))

    jobs = [(target, port) for target in targets for port in ports]
    print(f"sniX 1.0.0 | targets={len(targets)} probes={len(jobs)} workers={args.workers}")
    print("AUTHORIZED TESTING ONLY — use only against systems you own or are permitted to assess.\n")

    results: list[dict] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [pool.submit(probe, target, port, args.timeout) for target, port in jobs]
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            results.append(result)
            print_result(result)

    results.sort(key=lambda r: (r["target"], r["port"]))
    successful = sum(1 for r in results if r["ok"])
    print(f"\nSummary: {successful}/{len(results)} TLS endpoints responded successfully.")

    if args.output:
        report = {
            "tool": "sniX",
            "version": "1.0.0",
            "generated_at": now_iso(),
            "targets": targets,
            "ports": ports,
            "results": results,
        }
        try:
            with open(args.output, "w", encoding="utf-8") as fh:
                json.dump(report, fh, indent=2, ensure_ascii=False)
            print(f"JSON report: {args.output}")
        except OSError as exc:
            print(f"[!] cannot write report: {exc}", file=sys.stderr)
            return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
