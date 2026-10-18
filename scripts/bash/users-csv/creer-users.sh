#!/bin/bash
# Création d'utilisateurs Linux à partir d'un fichier CSV
# Format attendu (séparateur ;) : login;prenom;nom;groupe
# Usage : sudo ./creer-users.sh [-n] fichier.csv
#   -n : simulation, n'applique rien

SIMULATION=0
LOG="/var/log/creer-users.log"

if [ "$1" = "-n" ]; then
    SIMULATION=1
    shift
fi

CSV="$1"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG"
}

# Vérifications de base
if [ -z "$CSV" ]; then
    echo "Usage : sudo $0 [-n] fichier.csv"
    exit 1
fi

if [ ! -f "$CSV" ]; then
    echo "Fichier introuvable : $CSV"
    exit 1
fi

if [ "$(id -u)" -ne 0 ] && [ "$SIMULATION" -eq 0 ]; then
    echo "Ce script doit être lancé en root (sudo)."
    exit 1
fi

# En simulation on n'écrit pas dans /var/log
if [ "$SIMULATION" -eq 1 ]; then
    LOG="/dev/null"
    echo "Mode simulation : aucune modification ne sera faite."
fi

# Les mots de passe temporaires vont dans un fichier lisible par root seulement
# (créé au premier utilisateur, pour ne pas laisser de fichier vide)
MDP_FICHIER="mdp-temporaires-$(date '+%Y%m%d-%H%M%S').txt"

crees=0
ignores=0
erreurs=0
ligne_num=0

while IFS=';' read -r login prenom nom groupe; do
    ligne_num=$((ligne_num + 1))

    # Ligne vide
    if [ -z "$login" ]; then
        continue
    fi

    # Login en minuscules, uniquement lettres, chiffres, point, tiret
    login=$(echo "$login" | tr '[:upper:]' '[:lower:]')
    if ! echo "$login" | grep -Eq '^[a-z][a-z0-9.-]{1,31}$'; then
        log "ERREUR ligne $((ligne_num + 1)) : login invalide '$login'"
        erreurs=$((erreurs + 1))
        continue
    fi

    if [ -z "$groupe" ]; then
        groupe="utilisateurs"
    fi

    # L'utilisateur existe déjà : on ne touche à rien
    if id "$login" >/dev/null 2>&1; then
        log "IGNORE : $login existe déjà"
        ignores=$((ignores + 1))
        continue
    fi

    if [ "$SIMULATION" -eq 1 ]; then
        echo "[simulation] créerait $login ($prenom $nom), groupe $groupe"
        crees=$((crees + 1))
        continue
    fi

    # Création du groupe s'il n'existe pas
    if ! getent group "$groupe" >/dev/null; then
        groupadd "$groupe"
        log "Groupe créé : $groupe"
    fi

    if useradd -m -s /bin/bash -c "$prenom $nom" -g "$groupe" "$login"; then
        mdp=$(openssl rand -base64 9)
        echo "$login:$mdp" | chpasswd
        # Oblige l'utilisateur à changer son mot de passe à la première connexion
        chage -d 0 "$login"
        if [ ! -f "$MDP_FICHIER" ]; then
            touch "$MDP_FICHIER"
            chmod 600 "$MDP_FICHIER"
        fi
        echo "$login;$mdp" >> "$MDP_FICHIER"
        log "OK : $login créé ($prenom $nom, groupe $groupe)"
        crees=$((crees + 1))
    else
        log "ERREUR : useradd a échoué pour $login"
        erreurs=$((erreurs + 1))
    fi
# tail -n +2 saute la ligne d'en-tête, tr enlève les \r des fichiers Windows
done < <(tail -n +2 "$CSV" | tr -d '\r')

echo ""
echo "Résumé : $crees créé(s), $ignores ignoré(s), $erreurs erreur(s)"
if [ "$SIMULATION" -eq 0 ] && [ "$crees" -gt 0 ]; then
    echo "Mots de passe temporaires dans : $MDP_FICHIER (à transmettre puis supprimer)"
fi
