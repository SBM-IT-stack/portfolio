#!/usr/bin/env bash
# install.sh : installe les dotfiles du repo en créant des liens symboliques
# vers le HOME de l'utilisateur, en sauvegardant d'abord ce qui existe déjà.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

FILES=(bash_aliases bashrc_extra)

echo "== Installation des dotfiles depuis $DOTFILES_DIR =="

mkdir -p "$BACKUP_DIR"

for file in "${FILES[@]}"; do
    target="$HOME/.$file"
    source="$DOTFILES_DIR/$file"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo "-> Sauvegarde de $target vers $BACKUP_DIR/"
        mv "$target" "$BACKUP_DIR/"
    fi

    echo "-> Lien symbolique : $target -> $source"
    ln -sf "$source" "$target"
done

# S'assurer que ~/.bashrc charge bien bashrc_extra
if ! grep -q "bashrc_extra" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Ajouté par dotfiles/install.sh" >> "$HOME/.bashrc"
    echo '[ -f ~/.bashrc_extra ] && source ~/.bashrc_extra' >> "$HOME/.bashrc"
    echo "-> Ligne d'inclusion ajoutée à ~/.bashrc"
fi

echo ""
echo "Installation terminée."
echo "Sauvegarde de tes anciens fichiers (si existants) : $BACKUP_DIR"
echo "Lance 'source ~/.bashrc' ou ouvre un nouveau terminal pour appliquer les changements."
