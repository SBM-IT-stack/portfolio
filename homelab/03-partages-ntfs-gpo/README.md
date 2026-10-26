# Homelab 03 : partages de fichiers, droits NTFS et lecteurs réseau par GPO

Troisième étape de mon homelab, après le contrôleur de domaine (`01-ad-ds`) et GLPI (`02-glpi`).

## Ce que ça fait

Je mets en place les dossiers partagés d'une petite entreprise fictive (Compta, RH, Direction, Commun) :

- un dossier par service sur le serveur, partagé en `Service$` (partage caché) ;
- des droits NTFS qui suivent la méthode AGDLP ;
- une GPO qui monte automatiquement le bon lecteur réseau selon le service de l'utilisateur.

Le script `creer-partages.ps1` crée les groupes, les dossiers, les droits et les partages à partir de `services.csv`. La GPO, je la fais à la main dans la console GPMC (étapes plus bas).

## Pourquoi je l'ai fait

En support, "je n'ai plus accès au dossier de la compta" ou "mon lecteur S: a disparu" font partie des demandes les plus courantes. Je voulais comprendre ce qu'il y a derrière : qui a le droit de quoi, d'où vient le lecteur, et comment vérifier sans tout casser.

## La méthode AGDLP en deux phrases

On ne donne jamais de droits directement à un utilisateur. Les **A**ccounts vont dans un groupe **G**lobal (par service), ce groupe va dans un groupe **D**omaine **L**ocal (par ressource et par niveau d'accès), et c'est ce dernier qui reçoit les **P**ermissions sur le dossier.

```
Utilisateur  ->  GG_Compta  ->  DL_Compta_Modif  ->  Modification sur D:\Partages\Compta
                                DL_Compta_Lecture ->  Lecture sur D:\Partages\Compta
```

Si la direction doit lire les dossiers de la compta, j'ajoute simplement `GG_Direction` dans `DL_Compta_Lecture`, sans toucher aux droits du dossier.

## Utilisation

Prérequis : un domaine AD qui fonctionne, le module ActiveDirectory (présent sur le DC), une OU `Groupes`, et un disque ou dossier pour les partages.

```powershell
# Adapter -OuGroupes au nom du domaine
.\creer-partages.ps1 -Csv .\services.csv -Racine D:\Partages -OuGroupes "OU=Groupes,DC=labo,DC=local"
```

Le script peut être relancé : il ne recrée pas ce qui existe déjà, il remet juste les droits NTFS au propre.

Ensuite, on range les utilisateurs dans les groupes globaux :

```powershell
Add-ADGroupMember -Identity GG_Compta -Members j.martin
# Pour Commun, tout le monde : on met "Utilisateurs du domaine" dans GG_Commun
Add-ADGroupMember -Identity GG_Commun -Members "Utilisateurs du domaine"
```

## Droits appliqués

| Qui | Droit NTFS |
|---|---|
| Administrateurs, SYSTEM | Contrôle total |
| DL_Service_Modif | Modification |
| DL_Service_Lecture | Lecture et exécution |

L'héritage est coupé sur chaque dossier de service, sinon les utilisateurs récupèreraient les droits du dossier parent. Côté partage SMB, je laisse "Modifier" aux utilisateurs authentifiés : c'est NTFS qui filtre réellement. L'option Access Based Enumeration est activée, donc un utilisateur ne voit que les dossiers auxquels il a accès.

## GPO : lecteurs réseau

1. Dans GPMC, créer une GPO `U_Lecteurs_Reseau` liée à l'OU des utilisateurs.
2. Configuration utilisateur > Préférences > Paramètres Windows > Mappages de lecteurs > Nouveau lecteur mappé.
3. Pour la compta : action **Mettre à jour**, emplacement `\\SRV-AD01\Compta$`, lettre `S:`, libellé `Compta`.
4. Onglet Commun : cocher **Ciblage au niveau de l'élément**, puis "Groupe de sécurité" = `GG_Compta`.
5. Refaire pareil pour chaque service, et `T:` pour Commun sans ciblage.

Sur le poste client :

```
gpupdate /force
gpresult /r          (vérifier que la GPO apparaît dans "Objets de stratégie de groupe appliqués")
net use              (liste des lecteurs montés)
```

## Vérifier les droits

```powershell
icacls D:\Partages\Compta
Get-SmbShare | Where-Object Name -like '*$'
Get-ADGroupMember DL_Compta_Modif
```

## Ce que je voudrais ajouter

- des sous-dossiers avec des droits différents (par exemple un dossier "Paie" visible seulement par une partie de la compta) ;
- les quotas avec FSRM et le blocage de certains types de fichiers ;
- les clichés instantanés (versions précédentes) pour qu'un utilisateur puisse récupérer un fichier supprimé sans passer par le support.
