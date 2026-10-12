# gestionnaire-taches-php

Une petite application CRUD full-stack : gestion de tâches avec base de données,
écrite en PHP natif (sans framework) pour montrer les fondamentaux : routing simple,
requêtes préparées PDO, séparation logique/affichage.

## Fonctionnalités

- Ajouter une tâche (titre + description)
- Changer son statut : À faire → En cours → Terminé
- Supprimer une tâche
- Persistance en base de données (SQLite par défaut, MySQL en option)
- Protection contre les injections SQL (requêtes préparées PDO) et le XSS (`htmlspecialchars`)

## Installation et lancement (zéro configuration)

Le projet utilise **SQLite** par défaut : pas besoin d'installer ni configurer de serveur
de base de données, un simple fichier `tasks.db` est créé automatiquement.

```bash
# Prérequis : PHP 8+ avec l'extension pdo_sqlite (incluse par défaut dans PHP)
cd public
php -S localhost:8000
```

Puis ouvrir [http://localhost:8000](http://localhost:8000) dans un navigateur.

## Passer à MySQL (optionnel)

1. Importer `sql/schema_mysql.sql` dans ta base MySQL/MariaDB
2. Dans `public/db.php`, commenter le bloc "SQLite" et décommenter le bloc "MySQL"
3. Renseigner tes identifiants de connexion dans le bloc MySQL

## Structure du projet

```
gestionnaire-taches-php/
├── public/
│   ├── index.php     # page principale : liste + formulaire d'ajout
│   ├── add.php       # traitement de l'ajout
│   ├── update.php    # traitement du changement de statut
│   ├── delete.php     # traitement de la suppression
│   ├── db.php        # connexion PDO (SQLite / MySQL)
│   └── style.css      # thème sombre inspiré terminal
├── sql/
│   └── schema_mysql.sql
└── tasks.db          # créé automatiquement au premier lancement (SQLite)
```

## Pourquoi ce projet

Écrit en PHP "vanilla" volontairement (sans Laravel/Symfony) pour montrer une
compréhension des bases : cycle requête/réponse, PDO, séparation des responsabilités ;
utile pour une candidature où le poste implique du PHP sur un existant (ERP, back-office...).

## Prochaines étapes possibles

- [ ] Authentification (login/mot de passe)
- [ ] Filtrer/trier les tâches par statut
- [ ] Passer les actions (ajout/suppression) en Ajax pour éviter les rechargements de page
