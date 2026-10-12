#!/bin/bash

# Script : update-system.sh
# Objectif : effectuer une mise à jour simple d'un système Debian/Ubuntu.
# Usage : bash update-system.sh

echo "=== Mise à jour de la liste des paquets ==="
sudo apt update

echo "=== Mise à niveau des paquets installés ==="
sudo apt upgrade -y

echo "=== Suppression des paquets inutiles ==="
sudo apt autoremove -y

echo "=== Nettoyage du cache local ==="
sudo apt autoclean

echo "=== Mise à jour terminée ==="
