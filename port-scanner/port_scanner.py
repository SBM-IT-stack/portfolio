#!/usr/bin/env python3
"""
port_scanner.py : scanner de ports TCP simple, à but pédagogique.

Usage éthique uniquement : n'utiliser que sur des machines/réseaux
t'appartenant ou pour lesquels tu as une autorisation explicite.
"""

import argparse
import json
import socket
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime

# Ports courants avec leur service standard (sous-ensemble de la table IANA)
COMMON_PORTS = {
    21: "FTP", 22: "SSH", 23: "Telnet", 25: "SMTP", 53: "DNS",
    80: "HTTP", 110: "POP3", 143: "IMAP", 443: "HTTPS", 445: "SMB",
    3306: "MySQL", 3389: "RDP", 5432: "PostgreSQL", 8080: "HTTP-alt",
}


def scan_port(host: str, port: int, timeout: float) -> bool:
    """Retourne True si le port TCP est ouvert."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(timeout)
        return sock.connect_ex((host, port)) == 0


def resolve_host(host: str) -> str:
    try:
        return socket.gethostbyname(host)
    except socket.gaierror:
        print(f"Erreur : impossible de résoudre l'hôte '{host}'", file=sys.stderr)
        sys.exit(1)


def run_scan(host: str, ports: list[int], timeout: float, max_workers: int = 100) -> dict:
    ip = resolve_host(host)
    open_ports = []

    print(f"Scan de {host} ({ip}), {len(ports)} port(s), début {datetime.now():%H:%M:%S}")

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(scan_port, ip, p, timeout): p for p in ports}
        for future in as_completed(futures):
            port = futures[future]
            try:
                if future.result():
                    service = COMMON_PORTS.get(port, "inconnu")
                    open_ports.append({"port": port, "service": service})
                    print(f"  [OUVERT]  {port}/tcp\t{service}")
            except Exception as exc:
                print(f"  Erreur sur le port {port} : {exc}", file=sys.stderr)

    open_ports.sort(key=lambda p: p["port"])

    return {
        "host": host,
        "ip": ip,
        "scanned_ports": len(ports),
        "open_ports": open_ports,
        "timestamp": datetime.now().isoformat(),
    }


def main():
    parser = argparse.ArgumentParser(description="Scanner de ports TCP simple.")
    parser.add_argument("host", help="Adresse IP ou nom d'hôte à scanner")
    parser.add_argument("--start", type=int, default=1, help="Premier port de la plage")
    parser.add_argument("--end", type=int, default=1024, help="Dernier port de la plage")
    parser.add_argument("--common", action="store_true",
                         help="Ne scanner que les ports courants (ignore --start/--end)")
    parser.add_argument("--timeout", type=float, default=0.5, help="Timeout par port (secondes)")
    parser.add_argument("--output", help="Chemin d'un fichier JSON pour exporter le résultat")

    args = parser.parse_args()

    if args.common:
        ports = sorted(COMMON_PORTS.keys())
    else:
        if args.start < 1 or args.end > 65535 or args.start > args.end:
            print("Erreur : plage de ports invalide (1-65535).", file=sys.stderr)
            sys.exit(1)
        ports = list(range(args.start, args.end + 1))

    result = run_scan(args.host, ports, args.timeout)

    print(f"\nTerminé : {len(result['open_ports'])} port(s) ouvert(s) sur {args.host}")

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        print(f"Résultat exporté vers {args.output}")


if __name__ == "__main__":
    main()
