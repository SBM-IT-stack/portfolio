# Inventaire de plusieurs postes vers CSV (PowerShell)

## Ce que ça fait

Le script lit une liste de postes Windows, se connecte à chacun en CIM (WinRM) et récupère les infos qu'on demande souvent en support : utilisateur connecté, fabricant, modèle, numéro de série, processeur, RAM, version de Windows, dernier démarrage, place sur le disque C:, adresse IP et MAC. Tout part dans un CSV avec une ligne par poste.

Un poste éteint ou qui refuse la connexion n'est pas oublié : il apparaît dans le CSV avec son statut (`Injoignable (ping)` ou `Erreur WinRM`), et le script le liste à la fin.

## Pourquoi je l'ai fait

Mon script `system-info.ps1` donne les infos d'un seul poste, celui sur lequel on le lance. En entreprise on a besoin de la même chose pour tout un service d'un coup, par exemple pour préparer un renouvellement de matériel ou repérer les disques presque pleins. C'était aussi l'occasion d'apprendre les sessions CIM à distance et l'export CSV.

## Comment l'utiliser

Prérequis : WinRM actif sur les postes (`Enable-PSRemoting` ou par GPO dans un domaine) et un compte qui a les droits d'administration dessus.

1. Copier `postes.exemple.txt` en `postes.txt` et y mettre les noms des postes.
2. Lancer le script :

```powershell
.\Get-InventaireParc.ps1 -ListePostes .\postes.txt
```

On peut aussi passer les postes directement et donner un autre compte :

```powershell
.\Get-InventaireParc.ps1 -Postes PC-COMPTA01,PC-ACCUEIL -Credential (Get-Credential)
```

Le fichier `inventaire-AAAA-MM-JJ.csv` est créé dans le dossier courant (option `-Fichier` pour changer le chemin). Il utilise le point-virgule comme séparateur pour s'ouvrir directement dans Excel en français.

## Sur quoi je l'ai testé

Je n'ai pas encore de domaine complet, donc j'ai d'abord testé la logique avec `tests/Test-Simulation.ps1` : il remplace `Test-Connection`, `New-CimSession` et `Get-CimInstance` par de fausses fonctions qui renvoient des valeurs connues, avec un poste qui répond, un poste éteint, un poste sans WinRM et un doublon dans la liste. Le test passe sous PowerShell 7.4. J'ai évité la syntaxe propre à PowerShell 7 pour que le script tourne aussi sous Windows PowerShell 5.1, la version installée de base sur les postes.

## Ce que je voudrais ajouter

- Récupérer la liste des postes directement depuis l'AD (`Get-ADComputer`) au lieu d'un fichier texte.
- Interroger les postes en parallèle pour gagner du temps sur un gros parc.
- Ajouter la liste des logiciels installés dans un second fichier.
