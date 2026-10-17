# Homelab 01 : installation d'un contrôleur de domaine

## Ce que c'est

Le premier morceau de mon homelab : un Windows Server 2022 promu contrôleur de domaine (AD DS + DNS) pour le domaine `sbm.lan`, avec un poste Windows client joint au domaine.

J'ai découpé l'installation en trois scripts PowerShell, plus un script de vérification. Chaque étape est aussi décrite en version graphique dans [installation.md](installation.md), parce qu'en entreprise on ne fait pas toujours tout en script.

## Pourquoi je l'ai fait

Presque tout le support N1/N2 en entreprise tourne autour de l'Active Directory : comptes, mots de passe, groupes, postes dans le domaine. Mes scripts de création d'utilisateurs depuis un CSV avaient besoin d'un vrai domaine pour être testés. Je voulais aussi comprendre pourquoi « c'est toujours le DNS » quand un poste n'arrive pas à rejoindre le domaine.

## Contenu

```
01-ad-ds/
├── README.md
├── installation.md            procédure complète + problèmes classiques
└── scripts/
    ├── 01-preparation.ps1     IP fixe, DNS, nom du serveur
    ├── 02-promotion-dc.ps1    rôle AD DS + création de la forêt
    ├── 03-post-installation.ps1   OU, zone inversée, redirecteur DNS
    └── verifier-dc.ps1        contrôles de santé du DC
```

## Utilisation

Sur le serveur, en PowerShell administrateur, dans l'ordre :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\01-preparation.ps1      # redémarre
.\scripts\02-promotion-dc.ps1     # redémarre
.\scripts\03-post-installation.ps1
.\scripts\verifier-dc.ps1
```

Les valeurs par défaut (nom, IP, domaine) se changent en paramètres, par exemple :

```powershell
.\scripts\01-preparation.ps1 -NomServeur "DC01" -IP "10.0.0.5" -Passerelle "10.0.0.1"
.\scripts\02-promotion-dc.ps1 -Domaine "test.lan" -NetBIOS "TEST"
```

## Ce que je voudrais ajouter

- un deuxième contrôleur de domaine pour voir la réplication
- le rôle DHCP sur le serveur, à la place des IP fixes côté clients
- quelques GPO simples (fond d'écran, mappage de lecteur réseau)

## Testé sur

VirtualBox, Windows Server 2022 en version d'évaluation pour le DC et Windows 11 Pro pour le client, sur un réseau NAT 192.168.10.0/24.
