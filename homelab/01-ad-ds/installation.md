# Installation pas à pas

## Le lab

| Machine | Système | Rôle | IP |
|---|---|---|---|
| SRV-DC01 | Windows Server 2022 (évaluation, avec interface graphique) | AD DS + DNS | 192.168.10.10 (fixe) |
| PC-01 | Windows 10 ou 11 Pro | poste client | 192.168.10.50 (fixe) |

Les deux VM sont dans VirtualBox, sur un **réseau NAT** nommé `LAB-SBM` en 192.168.10.0/24 avec le DHCP de VirtualBox désactivé. La passerelle de ce réseau est 192.168.10.1 et donne accès à Internet. Pour le serveur : 2 vCPU, 4 Go de RAM, disque de 60 Go.

Le client doit être en édition **Pro** : une édition Famille ne peut pas rejoindre un domaine.

## 1. Préparer le serveur

Après l'installation de Windows Server, j'ouvre PowerShell en administrateur et je lance :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\01-preparation.ps1
```

Le script pose l'IP fixe, met le DNS sur 127.0.0.1 et renomme la machine en SRV-DC01, puis redémarre. En graphique, c'est l'équivalent de : panneau de configuration > carte réseau > IPv4, puis Paramètres > Système > Renommer ce PC.

Pourquoi l'IP fixe d'abord : les postes vont chercher le domaine en interrogeant le DNS du DC. Si son IP change, plus personne ne le trouve.

## 2. Promouvoir en contrôleur de domaine

```powershell
.\scripts\02-promotion-dc.ps1
```

Le script installe le rôle AD DS, demande le mot de passe DSRM puis crée la forêt `sbm.lan` (NetBIOS `SBM`) avec le DNS. Le serveur redémarre tout seul. Au retour, on se connecte avec `SBM\Administrateur`.

En graphique : Gestionnaire de serveur > Ajouter des rôles > Services AD DS, puis le drapeau jaune > Promouvoir ce serveur en contrôleur de domaine > Ajouter une nouvelle forêt.

Le mot de passe DSRM sert uniquement à démarrer le serveur en mode restauration des services d'annuaire, par exemple pour restaurer l'AD. Il faut le noter quelque part de sûr.

## 3. Post-installation

```powershell
.\scripts\03-post-installation.ps1
```

Ce que ça fait :

- crée l'OU `SBM` avec `Utilisateurs`, `Ordinateurs`, `Serveurs`, `Groupes` dedans
- crée la zone DNS inversée pour 192.168.10.0/24
- ajoute un redirecteur DNS (1.1.1.1) pour que les postes puissent aller sur Internet
- redirige les nouveaux ordinateurs du domaine vers l'OU `Ordinateurs` (`redircmp`)

## 4. Vérifier

```powershell
.\scripts\verifier-dc.ps1
```

Il contrôle les services (NTDS, DNS, Netlogon, KDC), les partages SYSVOL et NETLOGON, l'enregistrement SRV qui permet aux postes de trouver le DC, la résolution externe, puis lance `dcdiag /q`.

## 5. Joindre le poste client

Sur PC-01 :

1. IP 192.168.10.50/24, passerelle 192.168.10.1, **DNS 192.168.10.10** (le DC, pas la box)
2. Test : `nslookup sbm.lan` doit répondre 192.168.10.10
3. En PowerShell administrateur :

```powershell
Add-Computer -DomainName "sbm.lan" -Credential "SBM\Administrateur" -Restart
```

Après le redémarrage, l'écran de connexion propose « Autre utilisateur » et on peut se connecter avec un compte du domaine. Côté serveur, PC-01 apparaît dans l'OU `SBM\Ordinateurs` de la console « Utilisateurs et ordinateurs Active Directory ».

## Les problèmes classiques

| Symptôme | Cause probable | Ce que je vérifie |
|---|---|---|
| « Impossible de contacter un contrôleur de domaine » à la jonction | Le client utilise un autre DNS que le DC | `ipconfig /all` sur le client, ligne Serveurs DNS |
| Le client rejoint le domaine mais n'a plus Internet | Pas de redirecteur sur le DC | `Get-DnsServerForwarder` sur le DC |
| Le bouton « Domaine » est grisé | Windows édition Famille | `winver` |
| Erreur d'heure à la connexion | Horloge du client trop décalée (Kerberos tolère 5 minutes) | `w32tm /query /status` |
