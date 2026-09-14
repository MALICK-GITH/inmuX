#!/usr/bin/env python3
"""Core TLS/SNI diagnostics for sniX Network.

Designed for authorized network diagnostics. No exploitation or credential attacks.
"""
from __future__ import annotations

import ipaddress
import socket
import ssl
from datetime import datetime, timezone


def parse_ports(raw: str) -> list[int]:
    ports: set[int] = set()
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = (int(x.strip()) for x in part.split("-", 1))
            if a > b:
                a, b = b, a
            ports.update(range(a, b + 1))
        else:
            ports.add(int(part))
    if not ports or any(p < 1 or p > 65535 for p in ports):
        raise ValueError("ports must be between 1 and 65535")
    return sorted(ports)


def expand_targets(values) -> list[str]:
    """Expand host/IP/CIDR targets, limiting CIDR discovery to 256 addresses."""
    output: list[str] = []
    for raw in values:
        target = str(raw).strip()
        if not target:
            continue
        try:
            net = ipaddress.ip_network(target, strict=False)
        except ValueError:
            output.append(target)
            continue
        if net.num_addresses > 256:
            raise ValueError("CIDR is too large; maximum is 256 addresses")
        output.extend(str(ip) for ip in net.hosts())
        if net.num_addresses == 1:
            output.append(str(net.network_address))
    return list(dict.fromkeys(output))


def _name_value(name: str):
    return name


def _cert_names(cert: dict) -> tuple[str | None, list[str]]:
    subject = cert.get("subject", ())
    cn = None
    for group in subject:
        for key, value in group:
            if key == "commonName":
                cn = value
                break
    sans = [value for kind, value in cert.get("subjectAltName", ()) if kind == "DNS"]
    return cn, sans


def _iso(ts: str | None) -> str | None:
    if not ts:
        return None
    try:
        dt = datetime.strptime(ts, "%b %d %H:%M:%S %Y %Z").replace(tzinfo=timezone.utc)
        return dt.isoformat()
    except ValueError:
        return ts


def probe(target: str, port: int, timeout: float = 3.0) -> dict:
    result = {
        "target": target,
        "port": port,
        "ok": False,
        "ip": None,
        "reverse_dns": None,
        "tls_version": None,
        "cipher": None,
        "alpn": None,
        "certificate": {},
        "error": None,
    }
    try:
        infos = socket.getaddrinfo(target, port, type=socket.SOCK_STREAM)
        if not infos:
            raise OSError("DNS resolution returned no address")
        family, socktype, proto, _, sockaddr = infos[0]
        ip = sockaddr[0]
        result["ip"] = ip
        try:
            result["reverse_dns"] = socket.gethostbyaddr(ip)[0]
        except (OSError, socket.herror):
            pass

        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        context.set_alpn_protocols(["h2", "http/1.1"])

        with socket.socket(family, socktype, proto) as raw:
            raw.settimeout(timeout)
            raw.connect(sockaddr)
            with context.wrap_socket(raw, server_hostname=target) as tls:
                result["ok"] = True
                result["tls_version"] = tls.version()
                cipher = tls.cipher()
                result["cipher"] = cipher[0] if cipher else None
                result["alpn"] = tls.selected_alpn_protocol()
                cert = tls.getpeercert()
                cn, sans = _cert_names(cert)
                result["certificate"] = {
                    "common_name": cn,
                    "san": sans,
                    "issuer": cert.get("issuer"),
                    "not_before": _iso(cert.get("notBefore")),
                    "not_after": _iso(cert.get("notAfter")),
                }
    except Exception as exc:
        result["error"] = f"{type(exc).__name__}: {exc}"
    return result


def print_result(result: dict) -> None:
    ok = result.get("ok")
    mark = "\033[92m✓\033[0m" if ok else "\033[91m✗\033[0m"
    target = result.get("target")
    port = result.get("port")
    print(f"{mark} {target}:{port}")
    if not ok:
        print(f"    error: {result.get('error')}")
        return
    print(f"    IP: {result.get('ip')}  reverse: {result.get('reverse_dns') or '-'}")
    print(f"    TLS: {result.get('tls_version') or '-'}  cipher: {result.get('cipher') or '-'}  ALPN: {result.get('alpn') or '-'}")
    cert = result.get("certificate") or {}
    print(f"    CN: {cert.get('common_name') or '-'}")
    sans = cert.get("san") or []
    print(f"    SAN: {', '.join(sans[:8]) if sans else '-'}")
    print(f"    Valid: {cert.get('not_before') or '-'} → {cert.get('not_after') or '-'}")
