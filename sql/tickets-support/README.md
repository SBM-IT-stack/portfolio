# Suivi de tickets de support en SQL

Une base SQLite qui reproduit en petit ce qu'il y a derrière un outil de ticketing : des demandeurs, des techniciens N1 et N2, des catégories, des délais à respecter selon la priorité, et un historique des changements de statut.

## Pourquoi je l'ai fait

J'ai installé GLPI dans mon homelab et traité quelques tickets avec. Ensuite je voulais comprendre comment les infos sont rangées dans la base, et surtout savoir sortir moi-même les chiffres qu'un responsable support demande : combien de tickets ouverts, qui est surchargé, est-ce qu'on respecte les délais.

C'est aussi la suite de mon projet [`inventaire-parc`](../inventaire-parc) : ici j'utilise en plus des vues, un trigger et des index.

## Contenu

- `schema.sql` : les 6 tables, 2 vues, 2 index et le trigger
- `donnees.sql` : 19 tickets fictifs sur deux semaines dans une petite PME
- `requetes.sql` : 11 requêtes de suivi (tickets ouverts par urgence, non assignés, charge par technicien, délai moyen par catégorie, respect du SLA, demandeurs récurrents, escalades N2...)
- `test-trigger.sql` : fait avancer un ticket de « nouveau » à « résolu » pour vérifier que l'historique se remplit

Le SLA est simple : un délai maximum en heures selon la priorité (4 h pour critique, 8 h pour haute, 24 h pour normale, 72 h pour basse).

Le trigger se déclenche quand le statut d'un ticket change : il ajoute une ligne dans `historique_statut`, et si le ticket passe en « resolu », il remplit la date de résolution.

## Utilisation

```bash
sqlite3 tickets.db < schema.sql
sqlite3 tickets.db < donnees.sql
sqlite3 -header -column tickets.db < requetes.sql
sqlite3 -header -column tickets.db < test-trigger.sql
```

`requetes.sql` ne modifie rien. `test-trigger.sql` modifie le ticket 17 : pour repartir de zéro, il suffit de relancer `schema.sql` puis `donnees.sql`.

## Testé sur

SQLite 3.45 sous Linux (Ubuntu). Les fonctions de date (`julianday`, `strftime`) sont propres à SQLite, il faudrait les adapter pour MariaDB (`TIMESTAMPDIFF`, `NOW()`).

## Limites et ce que je voudrais ajouter

- le délai est compté en heures calendaires : un ticket ouvert le vendredi soir est vite hors délai. Il faudrait ne compter que les heures ouvrées
- le temps passé « en attente » de l'utilisateur devrait mettre le chrono en pause
- relier les tickets aux postes de la base `inventaire-parc` pour voir quelles machines tombent le plus souvent en panne
- une version MariaDB
