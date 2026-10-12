# port-scanner

Un scanner de ports TCP en ligne de commande, écrit en Python (bibliothèque standard
uniquement, pas de dépendance externe). Détecte les ports ouverts sur une machine
et tente d'identifier le service standard associé.

> ⚠️ **Usage éthique uniquement.** N'utilise ce script que sur des machines/réseaux
> vous appartenant, ou pour lesquels vous avez une autorisation explicite. Scanner un système
> sans autorisation peut être illégal (en France : article 323-1 du Code pénal).

## Fonctionnalités

- Scan d'un port unique, d'une plage de ports, ou d'une liste de ports courants
- Multithreading pour accélérer le scan
- Timeout configurable
- Identification du service standard (HTTP, SSH, FTP, etc.) via la table IANA locale
- Export du résultat en JSON avec `--output`

## Utilisation

```bash
python3 port_scanner.py <cible> [options]
```

Exemples :

```bash
# Scanner les ports 1 à 1024 sur le localhost
python3 port_scanner.py 127.0.0.1 --start 1 --end 1024

# Scanner uniquement les ports courants (21, 22, 80, 443, ...)
python3 port_scanner.py 192.168.1.1 --common

# Exporter le résultat
python3 port_scanner.py 127.0.0.1 --start 1 --end 1024 --output resultat.json
```

## Pourquoi ce projet

Montre une compréhension pratique des sockets TCP et du fonctionnement réseau :
en cohérence avec des bases réseau/sécurité (type Cisco Networking Academy, TryHackMe).

## Prochaines étapes possibles

- [ ] Ajouter le scan UDP
- [ ] Ajouter la bannière de service (banner grabbing)
- [ ] Ajouter une sortie couleur dans le terminal
