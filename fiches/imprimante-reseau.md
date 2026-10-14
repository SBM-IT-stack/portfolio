# Fiche N2 : imprimante réseau qui ne répond plus

J'ai écrit cette fiche pour le cas classique où un ticket remonte du N1 avec « l'imprimante n'imprime plus pour personne ». Le N1 a déjà fait les vérifications de base, le but ici est de trouver si le problème vient de l'imprimante, du réseau ou du serveur d'impression.

Contexte supposé : une imprimante en IP fixe (ou en réservation DHCP), partagée par un serveur d'impression Windows, déployée sur les postes par GPO.

## Avant de commencer

Je relis le ticket et je vérifie ce que le N1 a déjà fait :

- l'imprimante est allumée, sans erreur sur l'écran (bourrage, papier, toner) ;
- le câble réseau est branché et le voyant de la prise clignote ;
- le problème touche plusieurs utilisateurs (sinon c'est plutôt un souci de poste, à renvoyer en N1).

Je note aussi le nom de la file d'impression, l'adresse IP attendue et l'heure du premier signalement. Si quelque chose a changé ce jour-là (coupure de courant, intervention réseau, mise à jour du serveur), c'est souvent la piste la plus rapide.

## Étape 1 : l'imprimante est-elle joignable ?

Depuis le serveur d'impression (pas depuis mon poste, car c'est le serveur qui envoie les travaux) :

```powershell
Test-Connection 192.168.10.50 -Count 4
Test-NetConnection 192.168.10.50 -Port 9100
```

Le port 9100 (RAW) est celui qu'utilisent la plupart des imprimantes réseau. Selon la configuration, le port peut aussi être 515 (LPR) ou 631 (IPP).

| Résultat | Ce que ça veut dire | Suite |
|----------|---------------------|-------|
| ping OK, port OK | l'imprimante répond, le problème est côté serveur | étape 3 |
| ping OK, port fermé | le service d'impression de l'imprimante est bloqué | redémarrer l'imprimante, puis étape 3 |
| ping KO | problème d'adresse ou de réseau | étape 2 |

Remarque : certaines imprimantes ne répondent pas au ping par configuration. Dans ce cas je me fie au test de port.

## Étape 2 : l'imprimante n'est pas joignable

Je vais voir l'imprimante et j'imprime la page de configuration réseau (menu de l'imprimante, souvent « Rapport réseau » ou « Configuration »). Elle donne l'adresse IP réellement utilisée.

**L'adresse a changé.** L'imprimante est souvent passée en DHCP après une réinitialisation ou une coupure, et elle a reçu une nouvelle adresse. Deux solutions : remettre l'adresse fixe sur l'imprimante, ou créer une réservation DHCP sur son adresse MAC (c'est ce que je préfère, l'adresse est gérée à un seul endroit). Sur le serveur DHCP :

```powershell
Get-DhcpServerv4Lease -ScopeId 192.168.10.0 | Where-Object ClientId -like "a4-5d-36*"
```

**Conflit d'adresse IP.** Si l'imprimante affiche la bonne adresse mais que le ping répond de façon bizarre, une autre machine a peut-être la même adresse. Je compare l'adresse MAC qui répond avec celle de l'imprimante :

```powershell
arp -a | findstr 192.168.10.50
```

Si la MAC ne correspond pas, je retrouve la machine en trop (table DHCP, table MAC du switch) et je corrige l'adresse.

**L'adresse est bonne mais rien ne passe.** Je vérifie côté réseau : la prise est bien brassée, le port du switch est actif et dans le bon VLAN. Si je n'ai pas accès au switch, j'escalade à l'équipe réseau avec le numéro de prise et l'adresse MAC de l'imprimante.

## Étape 3 : l'imprimante répond, mais rien ne sort

Le problème est souvent sur le serveur d'impression. Je regarde d'abord la file d'attente :

```powershell
Get-Printer -Name "IMP-COMPTA" | Select-Object Name, PrinterStatus, PortName
Get-PrintJob -PrinterName "IMP-COMPTA"
```

Un travail en erreur en tête de file bloque tous ceux qui suivent. Je le supprime (après avoir prévenu l'utilisateur concerné) :

```powershell
Remove-PrintJob -PrinterName "IMP-COMPTA" -ID 12
```

Si la file ne se vide pas, je redémarre le spouleur. Attention, ça coupe toutes les impressions du serveur pendant quelques secondes :

```powershell
Restart-Service Spooler
```

Ensuite je vérifie que le port de la file pointe bien vers la bonne adresse (utile si l'IP a été corrigée à l'étape 2) :

```powershell
Get-PrinterPort -Name "IP_192.168.10.50"
```

Si le port pointe vers une ancienne adresse, je crée un port avec la bonne IP et je l'associe à la file, plutôt que de recréer l'imprimante (les postes gardent leur connexion).

```powershell
Add-PrinterPort -Name "IP_192.168.10.60" -PrinterHostAddress "192.168.10.60"
Set-Printer -Name "IMP-COMPTA" -PortName "IP_192.168.10.60"
```

## Étape 4 : ça marche depuis le serveur, pas depuis les postes

J'imprime une page de test directement depuis le serveur. Si elle sort, le problème est entre les postes et le serveur :

- le partage est bien actif et les droits d'impression sont donnés au bon groupe ;
- la GPO de déploiement s'applique (`gpresult /r` sur un poste) ;
- le pilote a été mis à jour sur le serveur et les postes n'arrivent pas à le récupérer (message d'erreur sur le pilote à la connexion).

Sur un poste, supprimer et reconnecter l'imprimante (`\\SRV-PRINT\IMP-COMPTA`) règle souvent le dernier cas.

## Clôture du ticket

Avant de fermer, je fais imprimer un utilisateur depuis son poste et j'attends sa confirmation. Dans le ticket, je note la cause trouvée, ce que j'ai modifié (adresse, port, réservation DHCP, pilote) et le temps passé.

Si la cause était une perte d'adresse IP, je vérifie que la réservation DHCP existe bien, pour que ça ne recommence pas à la prochaine coupure de courant.

## Quand escalader

- le port du switch ou le VLAN est en cause et je n'ai pas les droits sur l'équipement réseau ;
- l'imprimante affiche une erreur matérielle (four, carte réseau) : ticket au prestataire ou au loueur ;
- le serveur d'impression lui-même a un problème (service qui plante en boucle, disque plein).

## Ce que je voudrais ajouter

Un petit script PowerShell qui teste toutes les imprimantes du serveur (ping et port 9100) et sort la liste de celles qui ne répondent pas, pour les repérer avant que les utilisateurs appellent.

## Sur quoi je l'ai testé

Les commandes PowerShell sont celles du module PrintManagement de Windows Server. Je les ai relues et je dois encore les rejouer dans mon homelab sur un Windows Server 2022 avec une imprimante virtuelle.
