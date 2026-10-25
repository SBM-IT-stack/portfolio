#!/usr/bin/env python3
"""Vérifie la date d'expiration des certificats TLS d'une liste de serveurs."""

import argparse
import csv
import socket
import ssl
from datetime import datetime, timezone

PORT_PAR_DEFAUT = 443


def lire_serveurs(chemin):
    """Lit le fichier de serveurs : une ligne = hote ou hote:port."""
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
                serveurs.append((ligne, PORT_PAR_DEFAUT))
    return serveurs


def recuperer_certificat(hote, port, contexte, delai):
    """Se connecte au serveur et renvoie le certificat sous forme de dict."""
    with socket.create_connection((hote, port), timeout=delai) as sock:
        # server_hostname sert au SNI et à la vérification du nom
        with contexte.wrap_socket(sock, server_hostname=hote) as tls:
            return tls.getpeercert()


def verifier(hote, port, contexte, seuil, delai):
    """Renvoie un dict avec le statut d'un serveur."""
    resultat = {"serveur": f"{hote}:{port}", "expire_le": "", "jours": "",
                "statut": "", "detail": ""}
    try:
        cert = recuperer_certificat(hote, port, contexte, delai)
    except ssl.SSLCertVerificationError as e:
        # code 10 = certificat expiré (code OpenSSL X509_V_ERR_CERT_HAS_EXPIRED)
        resultat["statut"] = "EXPIRE" if e.verify_code == 10 else "INVALIDE"
        resultat["detail"] = e.verify_message
        return resultat
    except (OSError, ssl.SSLError) as e:
        resultat["statut"] = "ERREUR"
        resultat["detail"] = str(e)
        return resultat

    # notAfter ressemble à "Jun  1 12:00:00 2027 GMT"
    fin = datetime.fromtimestamp(ssl.cert_time_to_seconds(cert["notAfter"]), timezone.utc)
    jours = (fin - datetime.now(timezone.utc)).days

    resultat["expire_le"] = fin.strftime("%d/%m/%Y")
    resultat["jours"] = jours
    resultat["statut"] = "ATTENTION" if jours < seuil else "OK"
    return resultat


def main():
    parser = argparse.ArgumentParser(description="Vérifie l'expiration des certificats TLS.")
    parser.add_argument("fichier", help="fichier texte avec un serveur par ligne (hote ou hote:port)")
    parser.add_argument("--seuil", type=int, default=30,
                        help="nombre de jours sous lequel on passe en ATTENTION (30 par défaut)")
    parser.add_argument("--ca", help="certificat de l'autorité interne (fichier .pem) si besoin")
    parser.add_argument("--csv", help="enregistre aussi le résultat dans ce fichier CSV")
    parser.add_argument("--delai", type=float, default=5, help="délai de connexion en secondes")
    args = parser.parse_args()

    contexte = ssl.create_default_context()
    if args.ca:
        contexte.load_verify_locations(cafile=args.ca)

    resultats = [verifier(h, p, contexte, args.seuil, args.delai)
                 for h, p in lire_serveurs(args.fichier)]

    print(f"{'SERVEUR':<30} {'EXPIRE LE':<12} {'JOURS':>6}  STATUT")
    for r in resultats:
        print(f"{r['serveur']:<30} {r['expire_le']:<12} {str(r['jours']):>6}  {r['statut']} {r['detail']}")

    if args.csv:
        with open(args.csv, "w", newline="", encoding="utf-8") as f:
            ecrivain = csv.DictWriter(f, fieldnames=resultats[0].keys() if resultats else [], delimiter=";")
            ecrivain.writeheader()
            ecrivain.writerows(resultats)
        print(f"\nRésultat enregistré dans {args.csv}")

    # code de sortie 1 si au moins un serveur pose problème (utile en tâche planifiée)
    probleme = any(r["statut"] != "OK" for r in resultats)
    raise SystemExit(1 if probleme else 0)


if __name__ == "__main__":
    main()
