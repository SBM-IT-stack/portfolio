# Tickets traités dans mon lab

Ce sont des tickets que j'ai ouverts moi-même dans GLPI pour m'entraîner, avec un compte "utilisateur" (post-only) d'un côté et mon compte technicien de l'autre. Chaque ticket suit le même schéma : demande, diagnostic, résolution, temps passé.

| N° | Titre | Catégorie | Priorité | Lien avec le reste du portfolio |
|----|-------|-----------|----------|---------------------------------|
| 1 | Compte verrouillé après les vacances | Comptes utilisateurs | Haute | [fiche reset mot de passe](../../../fiches/reset-mot-de-passe.md) |
| 2 | Arrivée d'un nouveau salarié | Comptes utilisateurs | Moyenne | [création users AD](../../../scripts/powershell/ad-users-csv/) |
| 3 | L'imprimante du 1er étage n'imprime plus | Matériel > Impression | Moyenne | [fiche imprimante réseau](../../../fiches/imprimante-reseau.md) |
| 4 | "Disque presque plein" sur un poste | Poste de travail | Basse | [nettoyage poste](../../../scripts/powershell/nettoyage-poste/) |

---

## Ticket 1 : compte verrouillé après les vacances

**Demande (utilisatrice) :** "Je n'arrive plus à me connecter à mon PC depuis mon retour, ça dit que mon compte est verrouillé."

**Diagnostic :**
- vérification de l'identité de la personne (rappel sur son poste fixe)
- dans la console Utilisateurs et ordinateurs AD : compte verrouillé, et mot de passe expiré pendant ses congés
- elle a essayé plusieurs fois l'ancien mot de passe, d'où le verrouillage

**Résolution :** déverrouillage du compte, mot de passe temporaire avec "changer au prochain logon", test de connexion avec elle au téléphone.

**Suivi GLPI :** une tâche "Déverrouillage + reset" (10 min), solution saisie, ticket clos après validation de l'utilisatrice.

---

## Ticket 2 : arrivée d'un nouveau salarié

**Demande (responsable) :** "Un commercial arrive lundi, il lui faut un compte et un poste."

**Diagnostic :** pas un incident mais une demande. J'ai changé le type du ticket en "Demande" et vérifié les infos manquantes (service, date d'arrivée, droits).

**Résolution :**
- création du compte dans l'AD (OU Commerciaux, groupe GG_Commerciaux)
- poste rattaché à l'utilisateur dans l'inventaire GLPI (onglet Éléments)
- mail au responsable avec l'identifiant (le mot de passe est donné en main propre le jour J)

**Suivi GLPI :** deux tâches (compte 15 min, préparation poste 30 min), ticket résolu avant la date d'arrivée.

---

## Ticket 3 : l'imprimante du 1er étage n'imprime plus

**Demande (utilisateur) :** "Mes impressions restent en attente depuis ce matin."

**Diagnostic :**
- d'autres personnes du même étage ont le même problème, donc ce n'est pas le poste
- `ping` vers l'IP de l'imprimante : pas de réponse
- sur place : l'imprimante avait pris une autre adresse en DHCP après une coupure de courant

**Résolution :** réservation DHCP créée pour l'imprimante (adresse MAC), redémarrage, files d'attente vidées sur les postes concernés.

**Suivi GLPI :** ticket lié à l'imprimante dans l'inventaire, solution notée pour qu'elle serve la prochaine fois. 40 min au total.

---

## Ticket 4 : "disque presque plein" sur un poste

**Demande (utilisateur) :** "Windows me dit que le disque C: est presque plein."

**Diagnostic :** 3 Go libres sur 120. Les fichiers temporaires et deux anciens profils d'utilisateurs partis prenaient la majorité de la place.

**Résolution :** passage de mon script de nettoyage (en mode test d'abord, puis réel), 28 Go récupérés. Conseil à l'utilisateur de ranger ses vidéos sur le partage réseau.

**Suivi GLPI :** priorité basse, traité dans la journée, 20 min.
