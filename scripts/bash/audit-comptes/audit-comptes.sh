#!/bin/bash
# Audit des comptes utilisateurs d'un serveur Linux
# Repère : comptes inactifs, mots de passe vides ou jamais changés,
# comptes UID 0 en plus de root, membres des groupes admin.
# Usage : sudo ./audit-comptes.sh [-j jours] [-o rapport.csv]
#   -j : nombre de jours sans connexion pour considérer un compte inactif (90 par défaut)
#   -o : enregistre aussi le détail des comptes dans un CSV (séparateur ;)

JOURS=90
CSV=""
UID_MIN=1000
UID_MAX=60000
GROUPES_ADMIN="sudo wheel adm"

while getopts "j:o:h" opt; do
    case "$opt" in
        j) JOURS="$OPTARG" ;;
        o) CSV="$OPTARG" ;;
        *) echo "Usage : sudo $0 [-j jours] [-o rapport.csv]"; exit 1 ;;
    esac
done

if ! [[ "$JOURS" =~ ^[0-9]+$ ]]; then
    echo "Le nombre de jours doit être un entier : $JOURS"
    exit 1
fi

# /etc/shadow n'est lisible qu'en root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être lancé en root (sudo) pour lire /etc/shadow."
    exit 1
fi

# On prend les bornes d'UID définies sur la machine si elles existent
if grep -q '^UID_MIN' /etc/login.defs 2>/dev/null; then
    UID_MIN=$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)
    UID_MAX=$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)
fi

AUJOURDHUI=$(( $(date +%s) / 86400 ))   # date du jour en nombre de jours depuis 1970
alertes=0

alerte() {
    echo "  [ALERTE] $1"
    alertes=$((alertes + 1))
}

# Date de dernière connexion d'un compte, au format AAAA-MM-JJ, ou "jamais"
derniere_connexion() {
    local ligne
    ligne=$(lastlog -u "$1" 2>/dev/null | tail -n 1)
    if [ -z "$ligne" ] || echo "$ligne" | grep -q "Never logged in"; then
        echo "jamais"
        return
    fi
    # Les 5 derniers champs contiennent la date (ex : Oct 25 10:12:03 +0100 2026)
    date -d "$(echo "$ligne" | awk '{print $(NF-4), $(NF-3), $NF, $(NF-2), $(NF-1)}')" +%F 2>/dev/null || echo "inconnue"
}

echo "Audit des comptes sur $(hostname), le $(date '+%d/%m/%Y %H:%M')"
echo "Comptes humains : UID entre $UID_MIN et $UID_MAX, inactif au-delà de $JOURS jours"
echo

if [ -n "$CSV" ]; then
    echo "login;uid;shell;etat_mdp;dernier_changement_mdp;derniere_connexion;inactif" > "$CSV"
fi

# 1. Comptes avec UID 0 autres que root
echo "== Comptes avec UID 0 =="
while IFS=: read -r login _ uid _; do
    if [ "$uid" -eq 0 ] && [ "$login" != "root" ]; then
        alerte "$login a l'UID 0 (mêmes droits que root)"
    fi
done < /etc/passwd
echo

# 2. Membres des groupes qui donnent des droits d'administration
echo "== Membres des groupes d'administration =="
for groupe in $GROUPES_ADMIN; do
    if getent group "$groupe" > /dev/null; then
        membres=$(getent group "$groupe" | cut -d: -f4)
        echo "  $groupe : ${membres:-(aucun)}"
    fi
done
echo

# 3. Détail des comptes humains
echo "== Comptes humains =="
printf "  %-15s %-6s %-10s %-12s %-12s %s\n" "LOGIN" "UID" "MDP" "CHANGE LE" "CONNEXION" "REMARQUES"

while IFS=: read -r login _ uid _ _ _ shell; do
    if [ "$uid" -lt "$UID_MIN" ] || [ "$uid" -gt "$UID_MAX" ]; then
        continue
    fi

    # Champs de /etc/shadow : 2 = hash du mot de passe, 3 = dernier changement (en jours)
    hash=$(grep "^$login:" /etc/shadow | cut -d: -f2)
    dernier_chg=$(grep "^$login:" /etc/shadow | cut -d: -f3)
    remarques=""

    if [ -z "$hash" ]; then
        etat="VIDE"
    elif [[ "$hash" == "!"* ]] || [[ "$hash" == "*"* ]]; then
        etat="verrouille"
    else
        etat="actif"
    fi

    # 0 dans le champ 3 = changement forcé à la prochaine connexion
    if [ -z "$dernier_chg" ]; then
        date_chg="inconnue"
    elif [ "$dernier_chg" -eq 0 ]; then
        date_chg="a changer"
    else
        date_chg=$(date -d "@$((dernier_chg * 86400))" +%F)
    fi

    connexion=$(derniere_connexion "$login")

    # Inactif : jamais connecté, ou pas connecté depuis plus de JOURS jours
    inactif="non"
    if [ "$connexion" = "jamais" ]; then
        inactif="oui"
    elif [ "$connexion" != "inconnue" ]; then
        jours_depuis=$(( AUJOURDHUI - $(date -d "$connexion" +%s) / 86400 ))
        if [ "$jours_depuis" -gt "$JOURS" ]; then
            inactif="oui"
        fi
    fi

    # Un compte verrouillé ou sans shell ne peut pas se connecter, l'inactivité est normale
    peut_se_connecter=1
    if [ "$etat" = "verrouille" ] || [[ "$shell" == */nologin ]] || [[ "$shell" == */false ]]; then
        peut_se_connecter=0
    fi

    if [ "$etat" = "VIDE" ]; then
        remarques="mot de passe vide"
    fi
    if [ "$inactif" = "oui" ] && [ "$peut_se_connecter" -eq 1 ]; then
        remarques="${remarques:+$remarques, }inactif, à désactiver ?"
    fi
    if [ "$date_chg" != "inconnue" ] && [ "$date_chg" != "a changer" ] && \
       [ $(( AUJOURDHUI - dernier_chg )) -gt 365 ] && [ "$etat" = "actif" ]; then
        remarques="${remarques:+$remarques, }mdp de plus d'un an"
    fi

    printf "  %-15s %-6s %-10s %-12s %-12s %s\n" "$login" "$uid" "$etat" "$date_chg" "$connexion" "$remarques"

    if [ -n "$remarques" ]; then
        alertes=$((alertes + 1))
    fi

    if [ -n "$CSV" ]; then
        echo "$login;$uid;$shell;$etat;$date_chg;$connexion;$inactif" >> "$CSV"
    fi
done < /etc/passwd

echo
if [ "$alertes" -eq 0 ]; then
    echo "Aucun point à signaler."
else
    echo "$alertes point(s) à vérifier."
fi

if [ -n "$CSV" ]; then
    echo "Détail enregistré dans $CSV"
fi

# Code retour 2 s'il y a des alertes, pratique pour un cron ou une supervision
if [ "$alertes" -gt 0 ]; then
    exit 2
fi
exit 0
