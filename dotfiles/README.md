# dotfiles

Ma configuration personnelle de terminal Linux (Bash) : alias, prompt personnalisé,
et un script d'installation qui symlink tout proprement sans écraser tes fichiers existants.

## Pourquoi ce repo

C'est le classique du développeur Linux : montrer ma personnalité via ma configuration et personnalisation
de mon environnement au quotidien. Et non je n'utilise pas Arch. 

## Contenu

- `bash_aliases` : une trentaine d'alias utiles (navigation, git, système, sécurité de base)
- `bashrc_extra` : prompt personnalisé (affiche la branche git courante et le code de retour
  de la dernière commande), options d'historique améliorées
- `install.sh` : script d'installation : sauvegarde des fichiers existants dans
  `~/.dotfiles_backup_<date>/` puis crée les liens symboliques

## Installation

```bash
git clone https://github.com/SBM-IT-stack/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
source ~/.bashrc
```

## Aperçu du prompt

```
[✓] sebastien@debian:~/projets/dotfiles (main) $
[✗] sebastien@debian:~/projets/dotfiles (main) $   ← après une commande en échec
```

## Personnaliser

- Ajoutez vos propres alias dans `bash_aliases`
- Modifiez les couleurs du prompt dans `bashrc_extra` (variables `COLOR_*` en haut du fichier)

## Prochaines étapes possibles

- [ ] Ajouter une config `tmux.conf`
- [ ] Ajouter une config `vimrc` minimale
- [ ] Rendre le script compatible zsh
