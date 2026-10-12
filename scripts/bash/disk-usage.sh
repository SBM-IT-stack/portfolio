#!/bin/bash

# Script : disk-usage.sh
# Objectif : afficher l'utilisation disque de manière lisible.
# Usage : bash disk-usage.sh

echo "=== Espace disque disponible ==="
df -h

echo ""
echo "=== Taille des dossiers dans /home ==="
du -sh /home/* 2>/dev/null

echo ""
echo "=== Inodes disponibles ==="
df -i
