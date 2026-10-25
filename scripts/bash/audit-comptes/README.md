# Audit des comptes utilisateurs Linux

## Ce que ça fait

Le script `audit-comptes.sh` passe en revue les comptes d'un serveur Linux et signale ce qui mérite une vérification :

- les comptes qui ont l'UID 0 en plus de root (ils ont les mêmes droits que root)
- les membres des groupes d'administration (`sudo`, `wheel`, `adm`)
- pour chaque compte humain : état du mot de passe (actif, verrouillé ou vide), date du dernier changement, dernière connexion
- les comptes inactifs depuis plus de N jours, les mots de passe vides et ceux qui n'ont pas changé depuis plus d'un an

Il peut aussi enregistrer le détail dans un CSV. Le script ne modifie rien, il se contente de lire `/etc/passwd`, `/etc/shadow`, `/etc/group` et `lastlog`.

## Pourquoi je l'ai fait

Après mon script de création d'utilisateurs depuis un CSV, je voulais travailler l'autre bout de la vie d'un compte : ceux qui restent actifs après un départ, un stagiaire sans mot de passe, un compte de test oublié avec les droits root. C'est le genre de vérification qu'on fait avant un audit ou quand on récupère un serveur qu'on ne connaît pas. Ça m'a obligé à comprendre la structure de `/etc/shadow` (hash, dates en jours depuis 1970, verrouillage avec `!`).

## Utilisation

```bash
chmod +x audit-comptes.sh

# Audit avec le seuil par défaut (90 jours sans connexion)
sudo ./audit-comptes.sh

# Seuil à 30 jours et export CSV
sudo ./audit-comptes.sh -j 30 -o audit.csv
```

Exemple de sortie (sur ma VM de test) :

```
== Comptes avec UID 0 ==
  [ALERTE] toor a l'UID 0 (mêmes droits que root)

== Membres des groupes d'administration ==
  sudo : ubuntu,jdupont
  adm : ubuntu

== Comptes humains ==
  LOGIN           UID    MDP        CHANGE LE    CONNEXION    REMARQUES
  jdupont         1001   actif      2026-10-25   2026-10-23
  pbernard        1002   actif      2025-03-01   2026-04-08   inactif, à désactiver ?, mdp de plus d'un an
  mmartin         1003   actif      a changer    jamais       inactif, à désactiver ?
  stagiaire       1004   VIDE       2026-10-25   jamais       mot de passe vide, inactif, à désactiver ?
  svc_backup      1005   verrouille 2026-10-25   jamais

4 point(s) à vérifier.
```

Les comptes verrouillés ou sans shell (`nologin`, `false`) ne sont pas signalés comme inactifs, puisqu'ils ne peuvent pas se connecter de toute façon.

Le script renvoie le code 0 si tout va bien et 2 s'il y a des points à vérifier, ce qui permet de le lancer depuis cron et de réagir seulement en cas d'alerte.

## Ce que je voudrais ajouter

- une option pour verrouiller directement les comptes inactifs (avec confirmation)
- la lecture du fichier `/etc/sudoers` et de `/etc/sudoers.d/`, pas seulement des groupes
- le support de `lastlog2`, qui remplace `lastlog` sur certaines distributions récentes

## Testé sur

Ubuntu 24.04, en root, avec des comptes créés exprès : un compte normal membre de `sudo`, un compte inactif avec un vieux mot de passe, un compte qui doit changer son mot de passe, un compte sans mot de passe, un compte de service verrouillé et un compte `toor` avec l'UID 0. Vérifié avec `shellcheck`, et testé aussi sans root et avec un seuil invalide pour voir les messages d'erreur.
