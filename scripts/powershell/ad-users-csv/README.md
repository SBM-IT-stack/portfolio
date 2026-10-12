# ad-users-csv

Script PowerShell qui crée des comptes Active Directory à partir d'un fichier CSV.

En support, l'arrivée d'un nouveau salarié revient souvent : créer le compte, le mettre dans la bonne OU, remplir le service et la fonction, forcer le changement de mot de passe. Quand il y en a dix d'un coup, le faire à la main dans la console AD c'est long et on finit par se tromper. J'ai donc voulu automatiser ça.

## Ce que ça fait

- lit un CSV (séparateur `;`) avec les colonnes `Prenom;Nom;Service;Fonction`
- fabrique le login au format `prenom.nom`, sans accents ni espaces (`Inès Lefèvre-Garnier` donne `ines.lefevregarnier`)
- range chaque compte dans l'OU de son service (`OU=Informatique,OU=Utilisateurs,...`)
- saute les comptes qui existent déjà au lieu de planter
- oblige l'utilisateur à changer son mot de passe à la première connexion
- génère un rapport `rapport_creation.csv` avec le statut de chaque ligne

## Utilisation

Il faut le module ActiveDirectory (installé avec les outils RSAT, ou directement sur le contrôleur de domaine). Les OU des services doivent déjà exister.

Je conseille de lancer d'abord une simulation avec `-WhatIf`, rien n'est créé :

```powershell
.\New-ADUsersFromCsv.ps1 -CheminCsv .\utilisateurs.csv -OUBase "OU=Utilisateurs,DC=lab,DC=local" -Domaine "lab.local" -WhatIf
```

Puis pour de vrai :

```powershell
.\New-ADUsersFromCsv.ps1 -CheminCsv .\utilisateurs.csv -OUBase "OU=Utilisateurs,DC=lab,DC=local" -Domaine "lab.local"
```

Le mot de passe initial est demandé au lancement. Il n'est jamais écrit en clair, ni dans le script ni dans le rapport.

Le fichier `utilisateurs.csv` du dossier sert d'exemple.

## Ce que je voudrais ajouter

- gérer les homonymes (deux `jean.martin`) en ajoutant un chiffre
- ajouter chaque compte au groupe de son service
- créer l'OU automatiquement si elle n'existe pas

## Testé sur

PowerShell 7.4, avec les commandes AD simulées pour vérifier la logique (login, OU, doublons, rapport). La prochaine étape est de le passer sur le contrôleur de domaine de mon homelab.
