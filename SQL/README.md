# Inventaire de parc en SQL

Une petite base de données SQLite pour suivre les postes d'une entreprise : qui utilise quel poste, dans quel service, avec quels logiciels, et où en sont les garanties et les licences.

## Pourquoi je l'ai fait

En support, on passe beaucoup de temps à chercher des infos sur le parc : quel poste a encore Windows 10, quelle garantie expire bientôt, est-ce qu'on a assez de licences. Des outils comme GLPI font ça, mais je voulais d'abord comprendre comment ce genre de base est construite et savoir écrire les requêtes moi-même.

## Contenu

- `schema.sql` : création des 5 tables (service, utilisateur, poste, logiciel, installation) avec clés primaires, clés étrangères et quelques contraintes `CHECK`
- `donnees.sql` : un jeu de données fictif (10 postes, 9 utilisateurs, 6 logiciels)
- `requetes.sql` : 12 requêtes que j'utiliserais au quotidien (postes par service, postes sans antivirus, garanties, dépassement de licences, attribution d'un poste...)

Un utilisateur appartient à un service, un poste est attribué à zéro ou un utilisateur, et la table `installation` fait le lien entre les postes et les logiciels (relation plusieurs à plusieurs).

## Utilisation

```bash
sqlite3 parc.db < schema.sql
sqlite3 parc.db < donnees.sql
sqlite3 -header -column parc.db < requetes.sql
```

On peut aussi ouvrir la base avec `sqlite3 parc.db` et lancer les requêtes une par une.

Attention, les deux dernières requêtes sont des `UPDATE` : elles modifient les données. Pour repartir de zéro, il suffit de relancer `schema.sql` puis `donnees.sql`.

## Testé sur

SQLite 3.45 sous Linux. Les requêtes avec `date('now', ...)` sont propres à SQLite, il faudrait les adapter pour MariaDB (`CURDATE()`, `DATE_ADD`).

## Ce que je voudrais ajouter

- une table `intervention` pour garder l'historique des dépannages sur chaque poste
- une version MariaDB du schéma
- remplir la base automatiquement à partir de l'export CSV d'un script PowerShell d'inventaire
