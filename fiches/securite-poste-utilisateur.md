# Fiche technique : sécurité du poste utilisateur

## Objectif

Cette fiche présente une checklist simple pour améliorer la sécurité d’un poste utilisateur.

Elle s’adresse à un contexte de support informatique, de sensibilisation ou de premier niveau de cybersécurité défensive.

---

## 1. Mises à jour

Un poste doit être régulièrement mis à jour pour limiter les vulnérabilités.

À vérifier :

- mises à jour Windows ou Linux ;
- mises à jour navigateur ;
- mises à jour suite bureautique ;
- mises à jour antivirus ;
- redémarrage si nécessaire.

### Linux

```bash
sudo apt update
sudo apt upgrade
```

---

## 2. Comptes utilisateurs et droits

Bonnes pratiques :

- ne pas utiliser un compte administrateur au quotidien ;
- limiter les droits aux besoins réels ;
- supprimer ou désactiver les comptes inutilisés ;
- verrouiller la session en cas d’absence.

Risques :

- installation de logiciels non autorisés ;
- modification de paramètres sensibles ;
- propagation plus facile d’un malware.

---

## 3. Mots de passe et MFA

Bonnes pratiques :

- mot de passe long et unique ;
- gestionnaire de mots de passe si possible ;
- authentification multifacteur ;
- changement en cas de suspicion de compromission ;
- ne jamais partager son mot de passe.

---

## 4. Phishing

Signaux d’alerte :

- urgence artificielle ;
- pièce jointe inattendue ;
- faute dans le nom de domaine ;
- demande d’identifiants ;
- promesse ou menace inhabituelle ;
- expéditeur suspect.

Réaction conseillée :

1. ne pas cliquer ;
2. ne pas télécharger la pièce jointe ;
3. vérifier l’expéditeur ;
4. signaler le message ;
5. supprimer si confirmé malveillant.

---

## 5. Sauvegardes

Une sauvegarde utile doit être :

- régulière ;
- testée ;
- séparée du poste principal ;
- protégée contre les accès non autorisés.

Règle simple : 3-2-1

- 3 copies ;
- 2 supports différents ;
- 1 copie hors site ou cloud sécurisé.

---

## 6. Antivirus et pare-feu

À vérifier :

- antivirus actif ;
- base de signatures à jour ;
- pare-feu activé ;
- alertes traitées ;
- exceptions documentées.

---

## 7. Chiffrement et verrouillage

Bonnes pratiques :

- verrouillage automatique de session ;
- code PIN ou mot de passe au démarrage ;
- chiffrement disque si disponible ;
- prudence avec les clés USB ;
- blocage des supports inconnus si politique interne.

---

## Checklist rapide

| Point de contrôle | Statut |
|---|---|
| Système à jour | À vérifier |
| Antivirus actif | À vérifier |
| Pare-feu actif | À vérifier |
| Compte non administrateur utilisé au quotidien | À vérifier |
| MFA activée | À vérifier |
| Sauvegarde existante | À vérifier |
| Session verrouillée automatiquement | À vérifier |
| Sensibilisation phishing faite | À vérifier |
| Applications inutiles supprimées | À vérifier |
| Documentation mise à jour | À vérifier |

---

## Exemple de sensibilisation utilisateur

> Ne cliquez pas immédiatement sur un lien reçu par mail, surtout si le message insiste sur l’urgence. Vérifiez l’expéditeur, l’adresse du site et le contexte de la demande. En cas de doute, signalez le message au support informatique.

---

## Compétences travaillées

- cybersécurité défensive ;
- sensibilisation utilisateur ;
- support informatique ;
- gestion des accès ;
- bonnes pratiques poste de travail ;
- documentation technique ;
- RGPD et protection des données.
