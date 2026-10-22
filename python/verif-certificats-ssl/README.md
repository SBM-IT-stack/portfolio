# Vérification d'expiration des certificats SSL

Un script Python qui se connecte à une liste de serveurs en HTTPS (ou tout autre service TLS), lit leur certificat et affiche la date d'expiration avec le nombre de jours restants. Il signale en ALERTE les certificats qui expirent bientôt et en ERREUR ceux qu'il n'arrive pas à vérifier.

## Pourquoi je l'ai fait

Un certificat expiré, c'est un intranet ou un GLPI qui affiche une page d'avertissement à tout le monde, et une vague de tickets au support. Je voulais un moyen simple de voir venir l'échéance au lieu de la découvrir le jour même. C'est aussi l'occasion de comprendre comment marche la vérification d'un certificat (chaîne de confiance, nom du serveur, dates).

## Utilisation

Il faut Python 3, sans bibliothèque à installer (seulement `ssl`, `socket`, `csv` et `argparse`).

```
python3 verif_certs.py serveurs.txt
python3 verif_certs.py serveurs.txt --seuil 15
python3 verif_certs.py serveurs.txt --ca ca-homelab.pem --csv resultat.csv
```

- `--seuil N` : alerte si le certificat expire dans moins de N jours (30 par défaut)
- `--ca fichier.pem` : ajoute le certificat d'une autorité interne, pour les serveurs signés par une CA maison
- `--csv fichier.csv` : enregistre le résultat (séparateur point-virgule, s'ouvre directement dans Excel)
- `--timeout N` : délai de connexion en secondes (5 par défaut)

Exemple de sortie :

```
SERVEUR                             EXPIRE LE    JOURS  STATUT
localhost:8443                      21/10/2027     364  OK
localhost:9443                      31/10/2026       9  ALERTE
localhost:9999                                          ERREUR ([Errno 111] Connection refused)
```

Le script renvoie le code 0 si tout est OK, 1 s'il y a au moins une alerte ou une erreur, 2 si le fichier de serveurs est illisible. On peut donc le lancer dans une tâche planifiée (cron ou planificateur de tâches Windows) et réagir au code de sortie.

## Sur quoi je l'ai testé

Sous Linux avec Python 3.13. J'ai créé une petite autorité de certification avec `openssl`, signé deux certificats (un valable 365 jours, un valable 10 jours) et lancé deux serveurs de test avec `openssl s_server`. J'ai vérifié les cas suivants : certificat valide, certificat qui expire bientôt, port fermé, serveur appelé par son IP alors que le certificat est fait pour `localhost`, et CA interne non fournie.

## Ce que je voudrais ajouter

- envoyer un mail quand il y a une alerte
- lire la liste des serveurs depuis l'inventaire du parc plutôt que d'un fichier texte
- afficher l'émetteur du certificat pour savoir qui contacter pour le renouveler
