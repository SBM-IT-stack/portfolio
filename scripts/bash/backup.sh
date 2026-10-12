#!/usr/bin/env bash
#
# backup.sh : sauvegarde un dossier en .tar.gz horodaté, avec rotation et logs.
#
# Usage : ./backup.sh <source> <destination> [nb_sauvegardes_a_garder]
#
set -euo pipefail

# --- Paramètres ---
SOURCE_DIR="${1:-}"
DEST_DIR="${2:-}"
KEEP="${3:-5}"                      # nombre de sauvegardes à conserver par défaut
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
LOG_FILE="$DEST_DIR/backup.log"
ARCHIVE_NAME="backup_${TIMESTAMP}.tar.gz"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- Vérifications ---
if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "Usage : $0 <source> <destination> [nb_sauvegardes_a_garder]"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Erreur : le dossier source '$SOURCE_DIR' n'existe pas." >&2
    exit 1
fi

mkdir -p "$DEST_DIR"

# --- Sauvegarde ---
log "Début de la sauvegarde de '$SOURCE_DIR'"

if tar -czf "$DEST_DIR/$ARCHIVE_NAME" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>>"$LOG_FILE"; then
    SIZE=$(du -h "$DEST_DIR/$ARCHIVE_NAME" | cut -f1)
    log "Sauvegarde réussie : $ARCHIVE_NAME ($SIZE)"
else
    log "ÉCHEC de la sauvegarde de '$SOURCE_DIR'"
    exit 2
fi

# --- Rotation : ne garder que les $KEEP archives les plus récentes ---
NB_ARCHIVES=$(find "$DEST_DIR" -maxdepth 1 -name "backup_*.tar.gz" | wc -l)

if [ "$NB_ARCHIVES" -gt "$KEEP" ]; then
    NB_A_SUPPRIMER=$((NB_ARCHIVES - KEEP))
    log "Rotation : suppression de $NB_A_SUPPRIMER ancienne(s) sauvegarde(s) (garde les $KEEP plus récentes)"

    find "$DEST_DIR" -maxdepth 1 -name "backup_*.tar.gz" -printf '%T@ %p\n' \
        | sort -n \
        | head -n "$NB_A_SUPPRIMER" \
        | cut -d' ' -f2- \
        | while read -r old_archive; do
            log "Suppression : $(basename "$old_archive")"
            rm -f "$old_archive"
        done
fi

log "Fin de la sauvegarde. $KEEP sauvegarde(s) conservée(s) dans $DEST_DIR"
exit 0
