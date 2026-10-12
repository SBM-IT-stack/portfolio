# Fiche technique : réinitialisation de mot de passe et déverrouillage de compte

## Objectif

C'est la demande la plus fréquente au support niveau 1 : « je n'arrive plus à me connecter ». Cette fiche donne la marche à suivre dans un domaine Active Directory, de l'appel de l'utilisateur jusqu'à la clôture du ticket.

Le point le plus important n'est pas technique : il faut s'assurer que la personne au téléphone est bien le titulaire du compte. Un reset de mot de passe accordé à la mauvaise personne, c'est une porte ouverte sur le réseau.

---

## Symptômes possibles

- « Mot de passe incorrect » alors que l'utilisateur est sûr de lui.
- « Le compte référencé est actuellement verrouillé ».
- « Votre mot de passe a expiré et doit être changé ».
- L'utilisateur revient de congés et a oublié son mot de passe.
- Le compte se verrouille tout seul plusieurs fois par jour.

---

## Méthode

### 1. Vérifier l'identité du demandeur

Ne jamais réinitialiser un mot de passe sur simple demande par téléphone ou par mail sans vérification. Selon la procédure de l'entreprise :

- rappeler l'utilisateur sur son numéro professionnel de l'annuaire (pas celui qu'il donne) ;
- ou poser une question dont la réponse figure dans l'AD (matricule, service, responsable) ;
- ou faire valider la demande par son responsable.

Si un doute persiste, on ne fait rien et on escalade.

### 2. Regarder l'état du compte

Avant de toucher à quoi que ce soit, je regarde pourquoi l'utilisateur ne peut pas se connecter :

```powershell
Get-ADUser jean.martin -Properties LockedOut, Enabled, PasswordExpired, PasswordLastSet, BadLogonCount, LastBadPasswordAttempt |
    Select-Object Name, Enabled, LockedOut, PasswordExpired, PasswordLastSet, BadLogonCount, LastBadPasswordAttempt
```

Dans la console « Utilisateurs et ordinateurs Active Directory », les mêmes infos sont dans les propriétés du compte, onglet Compte.

| Ce que je vois | Ce que ça veut dire | Suite |
|---|---|---|
| `LockedOut = True` | trop d'essais ratés | étape 3 |
| `PasswordExpired = True` | le mot de passe a dépassé sa durée de vie | étape 4 |
| `Enabled = False` | compte désactivé (départ, sanction, oubli) | ne pas réactiver soi-même, escalade |
| rien d'anormal | l'utilisateur se trompe (clavier QWERTY, verr. maj) | vérifier avec lui avant de reset |

### 3. Déverrouiller le compte

Si l'utilisateur connaît encore son mot de passe, un simple déverrouillage suffit :

```powershell
Unlock-ADAccount -Identity jean.martin
```

Dans la console : propriétés du compte, onglet Compte, cocher « Déverrouiller le compte ».

### 4. Réinitialiser le mot de passe

Si l'utilisateur a oublié son mot de passe ou s'il a expiré :

```powershell
Set-ADAccountPassword -Identity jean.martin -Reset -NewPassword (Read-Host "Mot de passe temporaire" -AsSecureString)
Set-ADUser -Identity jean.martin -ChangePasswordAtLogon $true
Unlock-ADAccount -Identity jean.martin
```

Points à respecter :

- un mot de passe temporaire conforme à la politique (longueur, complexité) ;
- toujours cocher « L'utilisateur doit changer le mot de passe à la prochaine ouverture de session » ;
- transmettre le mot de passe temporaire par un canal sûr (de vive voix après vérification, SMS sur le numéro pro), jamais par mail ;
- ne jamais demander à l'utilisateur son ancien mot de passe.

### 5. Vérifier avec l'utilisateur

Rester en ligne pendant qu'il se connecte et choisit son nouveau mot de passe. Lui rappeler de le mettre à jour aussi sur son téléphone pro (messagerie, Wi-Fi), sinon le compte va se reverrouiller.

### 6. Documenter le ticket

Dans l'outil de ticketing (GLPI par exemple) :

- comment l'identité a été vérifiée ;
- ce qui a été constaté (verrouillé, expiré...) ;
- l'action faite (déverrouillage, reset) ;
- la confirmation que l'utilisateur a pu se connecter.

Ne jamais écrire le mot de passe temporaire dans le ticket.

---

## Quand escalader au niveau 2

- **Compte désactivé** : il faut l'accord du responsable ou des RH avant de le réactiver.
- **Verrouillages à répétition** : souvent un appareil qui tente de se connecter avec l'ancien mot de passe (téléphone, lecteur réseau mappé, tâche planifiée). Il faut chercher la source avec les événements 4740 sur le contrôleur de domaine.
- **Compte à privilèges** (admin, compte de service) : jamais traité au niveau 1.
- **Identité pas vérifiable**, ou demande suspecte (urgence, pression, appel « de la direction »).

---

## Erreurs à éviter

- Reset sans vérifier l'identité.
- Envoyer le mot de passe temporaire par mail.
- Oublier « doit changer à la prochaine connexion ».
- Réactiver un compte désactivé sans savoir pourquoi il l'est.
- Clôturer le ticket sans que l'utilisateur ait confirmé qu'il arrive à se connecter.
