# Comptes AD inactifs (PowerShell)

## Ce que ça fait

Le script parcourt les comptes utilisateurs Active Directory encore activés et repère ceux qui ne se sont pas connectés depuis un certain nombre de jours (90 par défaut). Il écrit un rapport CSV avec, pour chaque compte, la date de dernière connexion, le nombre de jours d'inactivité, la date de création et l'OU.

Avec l'option `-Desactiver`, il va plus loin : il désactive les comptes trouvés, note la date et la raison dans leur description, et peut les déplacer dans une OU dédiée (par exemple `OU=Desactives`). Rien n'est supprimé.

Quelques cas sont mis de côté exprès :

- les comptes intégrés (Administrateur, Invité, krbtgt) ;
- les comptes passés avec `-Exclure`, pratique pour les comptes de service ;
- les comptes créés il y a moins de X jours, qui n'ont simplement pas encore servi (un nouvel arrivant en congé, par exemple).

Un compte qui ne s'est jamais connecté apparaît avec `jamais`, et son inactivité est comptée depuis sa création.

## Pourquoi je l'ai fait

Après mon script de création de comptes depuis un CSV, je voulais traiter l'autre bout du cycle de vie : les départs. En entreprise, les comptes de stagiaires ou de salariés partis restent souvent actifs pendant des mois parce que personne n'a prévenu le support. C'est un vrai risque (un mot de passe qui fuite sur un compte que personne ne surveille), et c'est un point que les audits de sécurité regardent en premier.

## Comment l'utiliser

Il faut le module ActiveDirectory (outils RSAT, ou directement sur le contrôleur de domaine) et un compte qui a le droit de modifier les utilisateurs.

D'abord, juste le rapport, rien n'est modifié :

```powershell
.\Get-ComptesInactifs.ps1 -Jours 90 -Exclure svc.sauvegarde,svc.glpi
```

Ensuite, une simulation de la désactivation avec `-WhatIf`. Le rapport est quand même écrit, avec `simulation` dans la colonne Action :

```powershell
.\Get-ComptesInactifs.ps1 -Jours 90 -Exclure svc.sauvegarde -Desactiver -OUDesactives "OU=Desactives,DC=lab,DC=local" -WhatIf
```

Et quand la liste a été validée, la même commande sans `-WhatIf`.

L'option `-SearchBase` limite la recherche à une OU (par exemple `"OU=Utilisateurs,DC=lab,DC=local"`), et `-Fichier` change le chemin du rapport (par défaut `comptes-inactifs-AAAA-MM-JJ.csv`, séparateur `;` pour Excel).

## Sur quoi je l'ai testé

Sous PowerShell 7.4 avec `Test-Simulation.ps1`, qui remplace les commandes AD par de fausses fonctions. Le jeu de test contient un compte actif, un compte jamais connecté, un nom avec une virgule (`Dubois, Claire`), un compte tout juste créé, un compte de service exclu et un compte dont la désactivation échoue (accès refusé). Je vérifie les trois modes : rapport seul, `-WhatIf` et désactivation réelle. J'ai gardé une syntaxe compatible avec Windows PowerShell 5.1. La prochaine étape est de le lancer sur le contrôleur de domaine de mon homelab.

## Ce que je voudrais ajouter

- garder l'ancienne description au lieu de l'écraser ;
- faire la même chose pour les comptes ordinateurs (`Get-ADComputer`) ;
- envoyer le rapport par mail au responsable et lancer le tout en tâche planifiée une fois par mois.
