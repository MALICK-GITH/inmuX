#!/usr/bin/env python3
"""Interactive sniX Network console for authorized diagnostics."""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

from sniX import parse_ports, expand_targets, probe, print_result
import concurrent.futures

VERSION = "1.1.0"
MAX_WORKERS = 32


def clear() -> None:
    os.system("clear" if os.name != "nt" else "cls")


def banner() -> None:
    print("\033[96;1m╔══════════════════════════════════════════════╗\033[0m")
    print("\033[96;1m║              ⚡ sniX NETWORK ⚡              ║\033[0m")
    print("\033[96;1m║        NETWORK INTELLIGENCE CONSOLE         ║\033[0m")
    print("\033[96;1m╚══════════════════════════════════════════════╝\033[0m")
    print(f"  v{VERSION}  |  AUTHORIZED TESTING ONLY\n")


def ask(prompt: str, default: str = "") -> str:
    suffix = f" [{default}]" if default else ""
    value = input(f"\033[93m{prompt}{suffix}\033[0m: ").strip()
    return value or default


def run_scan(targets: list[str], ports: list[int], workers: int, timeout: float) -> list[dict]:
    jobs = [(t, p) for t in targets for p in ports]
    print(f"\n\033[90mScanning {len(targets)} target(s), {len(jobs)} probe(s)...\033[0m\n")
    results: list[dict] = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = [pool.submit(probe, t, p, timeout) for t, p in jobs]
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            results.append(result)
            print_result(result)
    return sorted(results, key=lambda r: (r["target"], r["port"]))


def scan_flow() -> list[dict]:
    raw = ask("Target(s), comma separated")
    targets = expand_targets(x for x in raw.split(",") if x.strip())
    if not targets:
        print("No targets supplied.")
        return []
    try:
        ports = parse_ports(ask("TLS ports", "443,8443"))
        timeout = float(ask("Timeout seconds", "3"))
        workers = int(ask("Workers", "12"))
        if timeout <= 0 or not 1 <= workers <= MAX_WORKERS:
            raise ValueError
    except ValueError:
        print("Invalid scan settings.")
        return []
    return run_scan(targets, ports, workers, timeout)


def save_report(results: list[dict]) -> None:
    if not results:
        print("No results to export.")
        return
    name = ask("Report filename", "snix-report.json")
    path = Path(name).expanduser()
    report = {"tool": "sniX", "version": VERSION, "results": results}
    try:
        path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Saved: {path}")
    except OSError as exc:
        print(f"Could not save report: {exc}")


def show_results(results: list[dict]) -> None:
    if not results:
        print("No results in the current session.")
        return
    ok = sum(1 for r in results if r["ok"])
    print(f"\nResults: {ok}/{len(results)} successful\n")
    for result in results:
        print_result(result)


def main() -> int:
    results: list[dict] = []
    while True:
        clear()
        banner()
        print("  [1] 🔎 SNI / TLS Discovery")
        print("  [2] 📊 Current Results")
        print("  [3] 💾 Export JSON Report")
        print("  [4] 🧹 Clear Session")
        print("  [0] 🚪 Exit")
        print()
        try:
            choice = input("\033[96msniX > \033[0m").strip().lower()
        except (KeyboardInterrupt, EOFError):
            print("\nBye.")
            return 0

        if choice == "1":
            results = scan_flow() or results
            input("\nPress ENTER to continue...")
        elif choice == "2":
            show_results(results)
            input("\nPress ENTER to continue...")
        elif choice == "3":
            save_report(results)
            input("\nPress ENTER to continue...")
        elif choice == "4":
            results.clear()
            print("Session cleared.")
            input("\nPress ENTER to continue...")
        elif choice in {"0", "q", "quit", "exit"}:
            print("Bye.")
            return 0
        else:
            print("Unknown option.")
            input("\nPress ENTER to continue...")


if __name__ == "__main__":
    raise SystemExit(main())
