#!/usr/bin/env python3
"""Vérifie la date d'expiration des certificats SSL/TLS d'une liste de serveurs."""

import argparse
import csv
import socket
import ssl
import sys
import time


def lire_serveurs(chemin):
    """Lit le fichier de serveurs : une ligne par serveur, format hote ou hote:port."""
    serveurs = []
    with open(chemin, encoding="utf-8") as f:
        for ligne in f:
            ligne = ligne.strip()
            if not ligne or ligne.startswith("#"):
                continue
            if ":" in ligne:
                hote, port = ligne.rsplit(":", 1)
                serveurs.append((hote, int(port)))
            else:
                serveurs.append((ligne, 443))
    return serveurs


def verifier(hote, port, contexte, timeout):
    """Renvoie (date d'expiration, jours restants) ou lève une exception."""
    with socket.create_connection((hote, port), timeout=timeout) as sock:
        with contexte.wrap_socket(sock, server_hostname=hote) as tls:
            cert = tls.getpeercert()

    # notAfter ressemble à "Jun  1 12:00:00 2027 GMT"
    expiration = ssl.cert_time_to_seconds(cert["notAfter"])
    jours = int((expiration - time.time()) // 86400)
    date = time.strftime("%d/%m/%Y", time.gmtime(expiration))
    return date, jours


def main():
    parser = argparse.ArgumentParser(description="Vérifie l'expiration des certificats SSL.")
    parser.add_argument("fichier", help="fichier texte avec la liste des serveurs")
    parser.add_argument("--seuil", type=int, default=30,
                        help="alerte si le certificat expire dans moins de N jours (30 par défaut)")
    parser.add_argument("--ca", help="certificat de l'autorité interne (fichier .pem)")
    parser.add_argument("--csv", help="enregistre aussi le résultat dans ce fichier CSV")
    parser.add_argument("--timeout", type=float, default=5, help="délai de connexion en secondes")
    args = parser.parse_args()

    try:
        serveurs = lire_serveurs(args.fichier)
    except OSError as e:
        print(f"Impossible de lire {args.fichier} : {e}")
        return 2

    # contexte par défaut : vérifie la chaîne de confiance et le nom du serveur
    contexte = ssl.create_default_context()
    if args.ca:
        contexte.load_verify_locations(args.ca)

    resultats = []
    for hote, port in serveurs:
        cible = f"{hote}:{port}"
        try:
            date, jours = verifier(hote, port, contexte, args.timeout)
            statut = "ALERTE" if jours < args.seuil else "OK"
            detail = ""
        except ssl.SSLCertVerificationError as e:
            date, jours, statut = "", "", "ERREUR"
            detail = e.verify_message  # ex : "certificate has expired"
        except (OSError, ssl.SSLError) as e:
            date, jours, statut = "", "", "ERREUR"
            detail = str(e)
        resultats.append([cible, date, jours, statut, detail])

    print(f"{'SERVEUR':<35} {'EXPIRE LE':<11} {'JOURS':>6}  STATUT")
    for cible, date, jours, statut, detail in resultats:
        ligne = f"{cible:<35} {date:<11} {str(jours):>6}  {statut}"
        if detail:
            ligne += f" ({detail})"
        print(ligne)

    if args.csv:
        with open(args.csv, "w", newline="", encoding="utf-8") as f:
            ecrivain = csv.writer(f, delimiter=";")
            ecrivain.writerow(["serveur", "expiration", "jours_restants", "statut", "detail"])
            ecrivain.writerows(resultats)
        print(f"\nRésultat enregistré dans {args.csv}")

    # code de sortie 1 s'il y a un problème, pratique pour une tâche planifiée
    probleme = any(r[3] != "OK" for r in resultats)
    return 1 if probleme else 0


if __name__ == "__main__":
    sys.exit(main())
