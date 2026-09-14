#!/usr/bin/env python3
"""Interactive sniX Network console for authorized diagnostics."""
from __future__ import annotations

import json
import os
from pathlib import Path
import concurrent.futures

from sniX import parse_ports, expand_targets, probe, print_result

VERSION = "1.2.0"
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


def explain_features() -> None:
    """Display a complete interactive guide to every current feature."""
    clear()
    banner()
    print("\033[96;1m📚 GUIDE COMPLET — FONCTIONNALITÉS sniX NETWORK\033[0m\n")

    sections = [
        ("🔎 1. SNI / TLS DISCOVERY", [
            "Analyse un nom de domaine ou une adresse IP sur un port TLS.",
            "Résout la cible et affiche son adresse IP.",
            "Effectue une connexion TLS avec SNI (Server Name Indication).",
            "Détecte la version TLS négociée et le cipher utilisé.",
            "Détecte ALPN : HTTP/2 (h2) ou HTTP/1.1 lorsqu'il est annoncé.",
            "Inspecte le certificat présenté par le serveur : CN, SAN, émetteur et dates de validité.",
            "Effectue aussi une résolution DNS inverse lorsque disponible.",
        ]),
        ("🎯 2. CIBLES", [
            "Accepte plusieurs cibles séparées par des virgules.",
            "Exemples : example.com, api.example.com, 192.0.2.10",
            "Accepte aussi un réseau CIDR pour une découverte bornée.",
            "La découverte CIDR est limitée à 256 adresses maximum par sécurité.",
        ]),
        ("🔌 3. PORTS TLS", [
            "Ports par défaut : 443 et 8443.",
            "Tu peux entrer plusieurs ports : 443,8443,9443.",
            "Les plages sont acceptées : 443-445.",
            "Les ports valides vont de 1 à 65535.",
        ]),
        ("⚡ 4. SCAN CONCURRENT", [
            "Plusieurs sondes peuvent être exécutées en parallèle.",
            "Le nombre de workers est configurable de 1 à 32.",
            "Les résultats apparaissent au fur et à mesure que les sondes terminent.",
            "Le timeout est configurable pour contrôler la durée d'attente par sonde.",
        ]),
        ("📊 5. RÉSULTATS DE SESSION", [
            "Tous les résultats du scan courant restent disponibles en mémoire.",
            "L'option Current Results affiche le nombre de succès et les détails.",
            "Les résultats contiennent aussi les erreurs lorsqu'une cible ne répond pas.",
        ]),
        ("💾 6. EXPORT JSON", [
            "Exporte les résultats de la session dans un fichier JSON.",
            "Le rapport contient le nom de l'outil, sa version et tous les résultats.",
            "Pratique pour l'analyse, l'archivage ou l'intégration avec d'autres outils.",
        ]),
        ("🧹 7. CLEAR SESSION", [
            "Efface uniquement les résultats actuellement conservés en mémoire.",
            "Cela ne supprime aucun fichier JSON déjà exporté.",
        ]),
        ("🛡️ 8. LIMITES ET UTILISATION", [
            "sniX est conçu pour les diagnostics réseau autorisés.",
            "Il ne réalise pas d'exploitation de vulnérabilités ni d'attaque de comptes.",
            "Les scans CIDR sont volontairement bornés à 256 adresses.",
            "Utilise l'outil uniquement sur des systèmes que tu possèdes ou pour lesquels tu as une autorisation.",
        ]),
    ]

    for title, items in sections:
        print(f"\033[95;1m{title}\033[0m")
        for item in items:
            print(f"  • {item}")
        print()

    print("\033[90mFlux recommandé : cible → ports → timeout → workers → scan → résultats → export JSON.\033[0m")
    input("\nAppuie sur ENTER pour revenir au menu...")


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
    try:
        targets = expand_targets(x for x in raw.split(",") if x.strip())
    except ValueError as exc:
        print(f"Invalid target range: {exc}")
        return []
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
        print("  [5] 📚 Guide / Toutes les fonctionnalités")
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
        elif choice == "5":
            explain_features()
        elif choice in {"0", "q", "quit", "exit"}:
            print("Bye.")
            return 0
        else:
            print("Unknown option.")
            input("\nPress ENTER to continue...")


if __name__ == "__main__":
    raise SystemExit(main())
