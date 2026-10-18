# Création d'utilisateurs Linux depuis un CSV

## Ce que ça fait

Le script `creer-users.sh` lit un fichier CSV et crée un compte Linux pour chaque ligne : dossier personnel, shell bash, nom complet en commentaire et groupe principal (créé s'il n'existe pas). Chaque compte reçoit un mot de passe temporaire aléatoire et doit le changer à la première connexion.

Il ignore les comptes qui existent déjà, refuse les logins invalides et note tout dans `/var/log/creer-users.log`. Les mots de passe temporaires sont écrits dans un fichier `mdp-temporaires-<date>.txt` en droits 600 (lisible par root seulement).

## Pourquoi je l'ai fait

J'avais déjà fait la même chose côté Windows avec l'Active Directory en PowerShell. Je voulais voir l'équivalent sous Linux, avec les commandes de base (`useradd`, `chpasswd`, `chage`, `groupadd`) plutôt qu'un outil tout fait.

## Utilisation

Format du CSV (séparateur `;`, première ligne = en-tête) :

```
login;prenom;nom;groupe
jdupont;Jean;Dupont;compta
pbernard;Paul;Bernard;
```

Si le groupe est vide, l'utilisateur va dans le groupe `utilisateurs`.

```bash
chmod +x creer-users.sh

# Simulation : affiche ce qui serait fait sans rien modifier
./creer-users.sh -n users.csv

# Création réelle
sudo ./creer-users.sh users.csv
```

Une fois les mots de passe transmis aux utilisateurs, il faut supprimer le fichier `mdp-temporaires-*.txt`.

Le script accepte aussi un CSV enregistré sous Windows (fins de ligne CRLF).

## Ce que je voudrais ajouter

- une option pour désactiver ou supprimer les comptes listés dans un CSV (départs)
- la gestion de groupes secondaires
- l'envoi du mot de passe par un autre canal que le fichier texte

## Testé sur

Ubuntu 24.04, en root, avec le fichier `users.csv` fourni (4 comptes valides et une ligne volontairement invalide). Vérifié avec `shellcheck` et en relançant le script une deuxième fois pour voir que les comptes existants sont bien ignorés.
