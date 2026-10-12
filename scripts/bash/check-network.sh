#!/bin/bash

# Script : check-network.sh
# Objectif : réaliser un diagnostic réseau simple.
# Usage : bash check-network.sh

ROUTER_IP="192.168.1.1"
PUBLIC_IP="8.8.8.8"
DOMAIN="google.com"

echo "=== Informations réseau de la machine ==="
ip addr show

echo ""
echo "=== Table de routage ==="
ip route

echo ""
echo "=== Test passerelle locale : $ROUTER_IP ==="
ping -c 4 "$ROUTER_IP"

echo ""
echo "=== Test connectivité Internet : $PUBLIC_IP ==="
ping -c 4 "$PUBLIC_IP"

echo ""
echo "=== Test résolution DNS : $DOMAIN ==="
ping -c 4 "$DOMAIN"

echo ""
echo "=== Diagnostic terminé ==="
