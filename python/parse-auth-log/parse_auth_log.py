#!/usr/bin/env python3
"""Compte les tentatives de connexion SSH échouées par adresse IP.

Lit un fichier de type /var/log/auth.log (Debian, Ubuntu) ou /var/log/secure
(Rocky, RHEL). Les fichiers compressés .gz issus de la rotation sont acceptés.

Exemples :
    python3 parse_auth_log.py /var/log/auth.log
    python3 parse_auth_log.py /var/log/auth.log /var/log/auth.log.2.gz --seuil 5
    python3 parse_auth_log.py exemple/auth.log --csv rapport.csv
    journalctl -u ssh --no-pager | python3 parse_auth_log.py -
"""

import argparse
import csv
import gzip
import re
import sys

# Ligne type :
# Oct 12 03:14:07 srv sshd[1234]: Failed password for invalid user admin from 203.0.113.5 port 52314 ssh2
ECHEC = re.compile(
    r"Failed password for (?:invalid user )?(?P<user>\S+) from (?P<ip>[0-9a-fA-F:.]+) port"
)
# rsyslog regroupe parfois les lignes identiques :
# ... sshd[1234]: message repeated 3 times: [ Failed password for root from ... ]
REPETE = re.compile(r"message repeated (?P<nb>\d+) times")
# Date en début de ligne : format syslog classique (Oct 12 03:14:07)
# ou format ISO utilisé par les versions récentes d'Ubuntu (2026-10-12T03:14:07...)
DATE = re.compile(r"^(\w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2}|\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})")


def ouvrir(chemin):
    """Ouvre le fichier en texte, qu'il soit compressé ou non."""
    if chemin == "-":
        # lecture depuis un pipe, par exemple journalctl
        return sys.stdin
    if chemin.endswith(".gz"):
        return gzip.open(chemin, "rt", encoding="utf-8", errors="replace")
    return open(chemin, "r", encoding="utf-8", errors="replace")


def analyser(fichiers):
    """Retourne un dictionnaire {ip: {"total", "users", "premiere", "derniere"}}."""
    stats = {}
    for chemin in fichiers:
        with ouvrir(chemin) as f:
            for ligne in f:
                if "sshd" not in ligne:
                    continue
                m = ECHEC.search(ligne)
                if not m:
                    continue

                nb = 1
                r = REPETE.search(ligne)
                if r:
                    nb = int(r.group("nb"))

                ip = m.group("ip")
                d = DATE.match(ligne)
                date = d.group(1) if d else "?"

                if ip not in stats:
                    stats[ip] = {"total": 0, "users": set(), "premiere": date, "derniere": date}
                stats[ip]["total"] += nb
                stats[ip]["users"].add(m.group("user"))
                stats[ip]["derniere"] = date
    return stats


def afficher(resultats):
    if not resultats:
        print("Aucune IP au-dessus du seuil.")
        return
    print(f"{'IP':<40} {'Échecs':>7}  {'Comptes testés':<30} Première / dernière")
    print("-" * 110)
    for ip, s in resultats:
        users = ", ".join(sorted(s["users"]))
        if len(users) > 30:
            users = users[:27] + "..."
        print(f"{ip:<40} {s['total']:>7}  {users:<30} {s['premiere']} / {s['derniere']}")


def ecrire_csv(resultats, chemin):
    with open(chemin, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["ip", "echecs", "comptes", "premiere", "derniere"])
        for ip, s in resultats:
            w.writerow([ip, s["total"], " ".join(sorted(s["users"])), s["premiere"], s["derniere"]])


def main():
    parser = argparse.ArgumentParser(description="Tentatives SSH échouées par IP")
    parser.add_argument("fichiers", nargs="*", default=["/var/log/auth.log"],
                        help="fichiers de log, du plus ancien au plus récent, ou - pour lire l'entrée standard (défaut : /var/log/auth.log)")
    parser.add_argument("--seuil", type=int, default=1,
                        help="n'affiche que les IP avec au moins N échecs (défaut : 1)")
    parser.add_argument("--top", type=int, default=0,
                        help="n'affiche que les N premières IP (0 = toutes)")
    parser.add_argument("--csv", metavar="FICHIER", help="exporte aussi le résultat en CSV")
    args = parser.parse_args()

    try:
        stats = analyser(args.fichiers)
    except FileNotFoundError as e:
        sys.exit(f"Fichier introuvable : {e.filename}")
    except PermissionError as e:
        sys.exit(f"Accès refusé : {e.filename} (relancer avec sudo ?)")

    # Tri du plus grand nombre d'échecs au plus petit
    resultats = [(ip, s) for ip, s in stats.items() if s["total"] >= args.seuil]
    resultats.sort(key=lambda x: x[1]["total"], reverse=True)
    if args.top > 0:
        resultats = resultats[:args.top]

    afficher(resultats)
    total = sum(s["total"] for s in stats.values())
    print(f"\n{total} échec(s) au total, {len(stats)} IP différente(s).")

    if args.csv:
        ecrire_csv(resultats, args.csv)
        print(f"Export CSV : {args.csv}")


if __name__ == "__main__":
    main()
