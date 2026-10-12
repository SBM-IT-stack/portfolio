# nettoyage-poste

Script PowerShell pour faire un peu de ménage sur un poste Windows : il vide les fichiers temporaires anciens et repère les profils utilisateurs qui ne servent plus.

C'est typiquement ce qu'on fait au support quand un utilisateur appelle parce que son disque C: est plein, ou sur un poste partagé où des dizaines de profils de stagiaires et d'intérimaires s'accumulent.

## Ce que ça fait

- supprime les fichiers de `%TEMP%` et `C:\Windows\Temp` plus vieux que N jours (7 par défaut)
- passe sans planter sur les fichiers verrouillés par un programme
- affiche combien de fichiers et de Mo ont été libérés
- liste les profils inutilisés depuis plus de N jours (90 par défaut), sans toucher aux profils système ni à celui de la personne connectée
- ne supprime les profils que si on ajoute `-SupprimerProfils`
- écrit tout dans un fichier log

## Utilisation

À lancer en administrateur pour avoir accès à `C:\Windows\Temp` et aux profils.

Simulation d'abord, rien n'est supprimé :

```powershell
.\Clear-Poste.ps1 -WhatIf
```

Nettoyage des temp seulement (les profils sont juste listés) :

```powershell
.\Clear-Poste.ps1 -JoursTemp 7
```

Avec suppression des profils inutilisés depuis 6 mois :

```powershell
.\Clear-Poste.ps1 -SupprimerProfils -JoursProfil 180
```

## Pourquoi `Remove-CimInstance` pour les profils

Supprimer juste le dossier `C:\Users\xxx` laisse la clé de registre du profil. Quand l'utilisateur se reconnecte, Windows lui charge un profil temporaire. Passer par `Win32_UserProfile` supprime les deux proprement.

## Ce que je voudrais ajouter

- vider la corbeille et le cache de Windows Update
- lancer le script à distance sur plusieurs postes
- exclure certains comptes (admin local, compte de service)

## Testé sur

PowerShell 7.4 sous Linux pour la partie fichiers temporaires (simulation, vrai nettoyage, dossier absent, fichiers récents conservés). La partie profils ne tourne que sous Windows : j'ai vérifié le filtre sur de faux profils, il reste à la passer sur une VM Windows.
