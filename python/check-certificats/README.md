# Vérification de l'expiration des certificats TLS

## Ce que ça fait

Le script lit une liste de serveurs (un par ligne, `hote` ou `hote:port`), se connecte à chacun en TLS et affiche la date d'expiration du certificat et le nombre de jours restants. Chaque serveur reçoit un statut :

| Statut | Signification |
|---|---|
| OK | certificat valide, plus de jours restants que le seuil |
| ATTENTION | certificat valide mais il expire bientôt (moins de 30 jours par défaut) |
| EXPIRE | le certificat est déjà expiré |
| INVALIDE | certificat refusé pour une autre raison (autosigné, mauvais nom, autorité inconnue) |
| ERREUR | connexion impossible (port fermé, nom introuvable, délai dépassé) |

Le script renvoie le code 0 si tout est OK et 1 sinon, ce qui permet de l'utiliser dans une tâche planifiée.

## Pourquoi je l'ai fait

Un certificat expiré, c'est une panne classique : l'intranet ou le webmail affiche une alerte de sécurité et les utilisateurs appellent le support. Je voulais un moyen simple de voir à l'avance ce qui va expirer, sans vérifier chaque site à la main dans le navigateur. Ça m'a aussi permis de comprendre comment un client vérifie un certificat (date, nom, chaîne de confiance).

## Comment l'utiliser

Il faut seulement Python 3, aucune bibliothèque à installer.

```bash
python3 check_certs.py serveurs.txt
python3 check_certs.py serveurs.txt --seuil 45 --csv resultat.csv
python3 check_certs.py serveurs.txt --ca autorite-lab.pem
```

- `--seuil` : nombre de jours sous lequel on passe en ATTENTION (30 par défaut)
- `--csv` : enregistre aussi le résultat en CSV (séparateur `;`, s'ouvre directement dans Excel)
- `--ca` : certificat de l'autorité interne, pour les serveurs signés par une autorité d'entreprise
- `--delai` : délai de connexion en secondes (5 par défaut)

Exemple de sortie :

```
SERVEUR                        EXPIRE LE     JOURS  STATUT
localhost:8441                 01/06/2027      219  OK
localhost:8442                 03/11/2026        9  ATTENTION
localhost:8443                                      EXPIRE certificate has expired
localhost:8444                                      INVALIDE self-signed certificate
localhost:8449                                      ERREUR [Errno 111] Connection refused
```

## Sur quoi je l'ai testé

Sous Linux avec Python 3.13. J'ai créé une petite autorité de certification avec OpenSSL, puis des certificats pour `localhost` : un valide, un qui expire dans 9 jours, un déjà expiré et un autosigné. J'ai lancé un serveur TLS local par certificat et vérifié que chaque cas donnait le bon statut, plus un port fermé pour le cas ERREUR.

## Ce que je voudrais ajouter

- afficher quand même la date d'expiration pour les certificats expirés ou invalides
- envoyer un mail quand un serveur passe en ATTENTION
- le lancer chaque semaine avec cron ou le planificateur de tâches Windows
- vérifier les services de mon homelab (GLPI, contrôleur de domaine en LDAPS sur le port 636)
