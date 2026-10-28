# Fiche N1/N2 : un utilisateur n'accède plus à un lecteur réseau

J'ai écrit cette fiche parce que "je n'ai plus mon lecteur S:" fait partie des tickets les plus courants en support. La cause peut être le réseau, les identifiants, les droits ou la GPO de mappage, et il faut avancer dans l'ordre pour ne pas chercher au mauvais endroit.

Dans les exemples, le serveur de fichiers s'appelle `SRV-FICHIERS`, le partage `Compta` et le domaine `LAB.LOCAL`. À adapter selon le parc.

## Symptômes typiques

- le lecteur apparaît avec une croix rouge dans l'explorateur
- message "Accès refusé" à l'ouverture du lecteur ou d'un dossier
- message "Le chemin réseau est introuvable" (erreur 53)
- le lecteur a tout simplement disparu après une ouverture de session

## 1. Qualifier la demande (N1)

Avant de toucher au poste, je pose quelques questions :

- Quel lecteur, quelle lettre, et quel est le message exact ? (une capture d'écran aide)
- Depuis quand ? Ça marchait hier ?
- Les collègues du même service ont-ils le même problème ?
- L'utilisateur est sur site ou en télétravail (VPN connecté ou pas) ?
- Il y a eu un changement récent : mot de passe modifié, changement de service, nouveau poste ?

Si **plusieurs utilisateurs** sont touchés, le problème vient sûrement du serveur ou du réseau : je passe directement à l'étape 5 ou j'escalade.

## 2. Vérifier que le serveur est joignable

Depuis le poste de l'utilisateur, dans PowerShell :

```powershell
ping SRV-FICHIERS
Resolve-DnsName SRV-FICHIERS
Test-NetConnection SRV-FICHIERS -Port 445
```

- Le nom ne se résout pas : problème DNS (voir la fiche diagnostic réseau local).
- Le ping répond mais `TcpTestSucceeded : False` sur le port 445 : le partage SMB est bloqué (pare-feu, service Serveur arrêté).
- En télétravail, je vérifie d'abord que le VPN est bien connecté.

Ensuite je teste l'accès direct sans passer par la lettre, en tapant dans l'explorateur :

```
\\SRV-FICHIERS\Compta
```

Si l'accès direct marche mais pas la lettre, c'est le mappage qui pose problème (étape 4).

## 3. Vérifier les identifiants

Cas très fréquent : l'utilisateur a changé son mot de passe et le poste utilise encore l'ancien.

```powershell
whoami
net use
```

`net use` liste les lecteurs mappés et leur état (OK, Déconnecté, Non disponible). Pour remettre le lecteur à zéro :

```powershell
net use S: /delete
net use S: \\SRV-FICHIERS\Compta /persistent:yes
```

Je regarde aussi le **Gestionnaire d'identification** (Panneau de configuration, Identifiants Windows) : s'il y a une entrée enregistrée pour `SRV-FICHIERS` avec un ancien mot de passe, je la supprime.

Si le compte est verrouillé ou le mot de passe expiré, je suis la fiche réinitialisation de mot de passe.

## 4. Vérifier la GPO de mappage

Dans la plupart des entreprises, les lecteurs sont créés par une GPO (Préférences, Mappages de lecteurs) ciblée sur un groupe.

```powershell
gpresult /r
gpupdate /force
```

Dans `gpresult /r`, partie Paramètres utilisateur, je vérifie que la GPO des lecteurs est bien dans la liste des stratégies appliquées et que l'utilisateur est dans le bon groupe. Après `gpupdate /force`, il faut souvent fermer et rouvrir la session.

## 5. Vérifier les droits (N2)

Si le serveur répond et que les identifiants sont bons mais que j'ai toujours "Accès refusé", c'est une question de droits.

Les groupes de l'utilisateur, vus depuis le poste :

```powershell
whoami /groups
```

Et côté AD (sur un poste avec les outils RSAT ou sur le contrôleur de domaine) :

```powershell
Get-ADPrincipalGroupMembership jdupont | Select-Object Name
```

Point important : quand on ajoute quelqu'un dans un groupe, ça ne prend effet qu'**à sa prochaine ouverture de session** (son jeton Kerberos contient l'ancienne liste de groupes). Je lui demande donc de se déconnecter et se reconnecter, ou je lance `klist purge` puis je remappe le lecteur.

Sur le serveur, il y a deux niveaux de droits :

```powershell
Get-SmbShareAccess -Name Compta   # droits du partage
icacls D:\Partages\Compta         # droits NTFS du dossier
```

C'est le droit **le plus restrictif** des deux qui s'applique. Exemple : partage en "Contrôle total" pour Tout le monde, mais NTFS en "Lecture" pour le groupe Compta, l'utilisateur ne pourra que lire.

Je ne modifie pas les droits moi-même sans validation : je vérifie dans le ticket ou avec le responsable que l'utilisateur doit bien avoir accès.

## 6. Vérifier le serveur (si plusieurs utilisateurs touchés)

```powershell
Get-Service LanmanServer
Get-SmbShare
Get-SmbSession | Select-Object ClientComputerName, ClientUserName
Get-PSDrive -PSProvider FileSystem
```

- `LanmanServer` (service Serveur) doit être en Running.
- Le partage doit apparaître dans `Get-SmbShare`.
- Un disque plein peut aussi bloquer l'écriture.

## Messages fréquents et pistes

| Message | Piste principale |
|---|---|
| Le chemin réseau est introuvable (53) | DNS, VPN, serveur éteint, port 445 |
| Accès refusé (5) | Droits partage ou NTFS, groupe AD, jeton pas à jour |
| Le mot de passe réseau spécifié est incorrect (86) | Identifiants en cache, mot de passe changé |
| Plusieurs connexions au même serveur avec des noms différents (1219) | `net use * /delete` puis remapper |

## Quand escalader

- le serveur ne répond plus pour personne
- des fichiers ont disparu (restauration via les versions précédentes ou la sauvegarde, à faire par l'admin)
- il faut modifier les droits d'un partage sans validation claire du besoin

## Exemple de clôture de ticket

> Lecteur S: inaccessible pour M. Dupont depuis son changement de mot de passe. Ancien identifiant enregistré pour SRV-FICHIERS dans le Gestionnaire d'identification. Entrée supprimée, lecteur remappé avec `net use`, accès vérifié avec l'utilisateur. Ticket clos.

## Ce que je voudrais ajouter

- un petit script PowerShell qui enchaîne les tests des étapes 2 et 3 et affiche un résumé
- des captures d'écran de la GPO de mappage dans mon homelab

## Sur quoi je l'ai testée

[à compléter : par exemple contrôleur de domaine du homelab (homelab/01-ad-ds) + un client Windows joint au domaine]
