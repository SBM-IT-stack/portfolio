# Homelab 02 : GLPI et traitement de tickets

## Ce que c'est

L'installation de GLPI 11 sur une VM Debian 13 dans mon lab, puis quelques tickets que j'ai traités de bout en bout comme si j'étais au support. GLPI est l'outil de gestion de parc et de helpdesk qu'on retrouve dans beaucoup d'entreprises et de collectivités en France.

## Pourquoi je l'ai fait

En alternance, je vais passer une bonne partie de mon temps dans un outil de tickets. Je voulais savoir l'installer moi-même et surtout comprendre le cycle d'un ticket : ouverture, prise en charge, tâches, solution, clôture.

## Ce qu'il y a dans le dossier

- `install-glpi.sh` : le script qui prépare la VM (Apache, PHP-FPM, MariaDB, GLPI)
- `tickets/README.md` : les tickets traités, avec diagnostic et résolution

## Mon lab

- VM Debian 13, 2 Go de RAM, 20 Go de disque, carte réseau sur le même réseau interne que le contrôleur de domaine du [homelab 01](../01-ad-ds/)
- une entrée DNS `glpi.lab.local` ajoutée sur le DC
- un client Windows 11 joint au domaine pour ouvrir les tickets côté utilisateur

## Installation

```bash
chmod +x install-glpi.sh
sudo ./install-glpi.sh
sudo mariadb-secure-installation   # pour sécuriser MariaDB (compte root, base de test)
```

Le script s'arrête si GLPI est déjà présent dans `/var/www/glpi`. À la fin, il affiche le mot de passe de la base, que je recopie dans l'assistant web.

Ensuite, dans le navigateur (`http://glpi.lab.local`) :

1. langue, licence, "Installer"
2. vérification des prérequis (tout doit être vert, sauf l'avertissement sur HTTPS en lab)
3. serveur `localhost`, utilisateur `glpi_user`, base `glpi`
4. connexion avec `glpi` / `glpi`

Après l'installation :

- changement du mot de passe des 4 comptes par défaut (`glpi`, `tech`, `normal`, `post-only`)
- suppression de `/var/www/glpi/install/install.php`
- création de catégories de tickets (Comptes utilisateurs, Poste de travail, Matériel > Impression, Réseau)
- création d'un technicien à mon nom et d'un utilisateur "test" en profil Self-Service

## Pourquoi sortir config, files et log du dossier web

Par défaut tout est dans `/var/www/glpi`. Je déplace la configuration (qui contient le mot de passe de la base) dans `/etc/glpi`, les données dans `/var/lib/glpi` et les journaux dans `/var/log/glpi`. Comme Apache ne sert que `/var/www/glpi/public`, ces fichiers ne sont pas accessibles depuis le navigateur. C'est aussi ce que GLPI recommande sur sa page de vérification de sécurité.

## Ce que je voudrais ajouter

- la synchronisation des utilisateurs avec l'Active Directory (annuaire LDAP)
- un agent GLPI sur le client Windows pour remonter l'inventaire tout seul
- la création de tickets par mail (collecteur)
- passer le site en HTTPS avec un certificat de mon autorité interne

## Testé sur

Debian 13 avec GLPI 11.0.4, PHP 8.4 et MariaDB des dépôts Debian.
