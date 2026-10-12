# backup-script

Un script Bash de sauvegarde automatisée : archive un dossier, horodate le résultat,
journalise l'opération et supprime automatiquement les sauvegardes trop anciennes
(rotation) pour ne pas saturer le disque.

## Fonctionnalités

- Archive `.tar.gz` horodatée (`backup_2026-08-27_14-30-00.tar.gz`)
- Rotation configurable : ne garde que les N dernières sauvegardes
- Journal des opérations dans `backup.log` (succès, erreurs, taille de l'archive)
- Code de sortie explicite (utile pour la supervision / cron)
- Aucune dépendance externe : uniquement `tar`, `find`, `du` (déjà présents sur toute distro Linux)

## Utilisation

```bash
chmod +x backup.sh
./backup.sh /chemin/à/sauvegarder /chemin/de/destination [nombre_de_sauvegardes_à_garder]
```

Exemple concret :

```bash
./backup.sh ~/projets /mnt/backups 7
# garde les 7 dernières sauvegardes, supprime les plus anciennes
```

## Automatiser avec cron

Pour lancer une sauvegarde tous les jours à 2h du matin :

```bash
crontab -e
# puis ajouter la ligne :
0 2 * * * /chemin/vers/backup.sh /home/utilisateur/projets /mnt/backups 7 >> /var/log/backup_cron.log 2>&1
```

## Pourquoi ce projet

Montre une utilisation concrète du shell scripting pour résoudre un vrai problème
(sauvegarde, rotation, logs), au-delà d'un simple "hello world" en bash.

## Prochaines étapes possibles

- [ ] Envoi d'une notification (mail/webhook) en cas d'échec
- [ ] Chiffrement de l'archive avec `gpg`
- [ ] Envoi de la sauvegarde vers un stockage distant (rsync/S3)
