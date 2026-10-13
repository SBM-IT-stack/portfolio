# Parseur de logs SSH : tentatives échouées par IP

## Ce que ça fait

Le script lit les logs d'authentification d'un serveur Linux (`/var/log/auth.log` sur Debian/Ubuntu, `/var/log/secure` sur Rocky/RHEL) et compte les mots de passe SSH refusés pour chaque adresse IP. Pour chaque IP, il affiche le nombre d'échecs, les comptes qui ont été testés et la date de la première et de la dernière tentative.

Il gère aussi :

- les fichiers compressés par la rotation (`auth.log.2.gz`)
- les lignes « message repeated N times » de rsyslog, comptées N fois
- la lecture depuis un pipe, pour les systèmes qui n'ont que journald
- l'export du résultat en CSV (séparateur `;`, s'ouvre directement dans Excel)

## Pourquoi je l'ai fait

Dès qu'un serveur a le port 22 ouvert sur Internet, les logs se remplissent de tentatives sur `root`, `admin`, `test`... Lire ça à la main avec `grep` devient vite pénible. Je voulais un résumé lisible pour repérer les IP à bloquer (pare-feu, fail2ban) et voir quels comptes sont visés. C'était aussi l'occasion de pratiquer les expressions régulières et `argparse` en Python.

## Utilisation

Python 3 suffit, aucune bibliothèque à installer.

```bash
# fichier par défaut (/var/log/auth.log), il faut souvent sudo pour le lire
sudo python3 parse_auth_log.py

# fichier de test fourni avec le projet
python3 parse_auth_log.py exemple/auth.log

# plusieurs fichiers (du plus ancien au plus récent), IP avec au moins 5 échecs
sudo python3 parse_auth_log.py /var/log/auth.log.2.gz /var/log/auth.log.1 /var/log/auth.log --seuil 5

# les 10 IP les plus actives, avec export CSV
sudo python3 parse_auth_log.py --top 10 --csv rapport.csv

# système sans rsyslog (journald uniquement)
journalctl -u ssh --no-pager | python3 parse_auth_log.py -
```

Exemple de sortie sur le fichier de test :

```
IP                                        Échecs  Comptes testés                 Première / dernière
--------------------------------------------------------------------------------------------------------------
203.0.113.5                                    7  admin, root, test              Oct 12 03:14:04 / Oct 13 01:05:30
198.51.100.23                                  3  oracle, postgres, ubuntu       Oct 12 04:02:47 / Oct 12 04:02:55
2001:db8::42                                   2  root                           Oct 12 11:20:13 / Oct 12 11:20:17
192.0.2.77                                     2  pi                             Oct 12 22:47:05 / Oct 12 22:47:09
192.168.1.20                                   1  seb                            Oct 12 08:31:40 / Oct 12 08:31:40

15 échec(s) au total, 5 IP différente(s).
```

Les adresses du fichier d'exemple sont des plages réservées à la documentation (RFC 5737 et RFC 3849), pas de vraies IP.

## Ce que je voudrais ajouter

- compter aussi les échecs par clé publique et les connexions réussies
- générer directement les commandes `ufw deny` pour les IP au-dessus du seuil
- ajouter l'année aux dates syslog pour mieux trier sur plusieurs mois

## Testé sur

- Python 3.13, avec le fichier `exemple/auth.log`, une copie compressée en `.gz` et une version au format de date ISO
- format des lignes repris de Debian 12 / Ubuntu (OpenSSH)
