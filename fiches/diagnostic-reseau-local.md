# Fiche technique : diagnostic réseau local

## Objectif

Cette fiche présente une méthode simple pour diagnostiquer un problème réseau sur un poste utilisateur.

Elle peut être utilisée dans un contexte de support informatique niveau 1 ou 2.

---

## Symptômes possibles

- L’utilisateur n’a plus accès à Internet.
- L’utilisateur ne peut pas accéder à une application web interne.
- Le poste ne voit plus les ressources du réseau local.
- Le Wi-Fi est connecté mais aucune page ne charge.
- Un nom de domaine ne répond plus.

---

## Méthode de diagnostic

### 1. Vérifier l’état physique ou logique de la connexion

Points à vérifier :

- câble Ethernet branché ;
- Wi-Fi activé ;
- carte réseau active ;
- voyant réseau présent ;
- mode avion désactivé ;
- VPN actif ou non.

### 2. Vérifier l’adresse IP

Sous Windows :

```powershell
ipconfig /all
```

Sous Linux :

```bash
ip addr
```

À contrôler :

- adresse IPv4 présente ;
- masque de sous-réseau ;
- passerelle par défaut ;
- serveur DNS ;
- adresse APIPA éventuelle en `169.254.x.x`.

Une adresse en `169.254.x.x` peut indiquer un problème DHCP.

### 3. Tester la passerelle locale

```bash
ping 192.168.1.1
```

Si la passerelle répond, le poste communique avec le réseau local.

Si elle ne répond pas :

- vérifier le câble ;
- vérifier le Wi-Fi ;
- vérifier la carte réseau ;
- vérifier le VLAN ou le port switch si contexte entreprise.

### 4. Tester Internet par adresse IP

```bash
ping 8.8.8.8
```

Si cela fonctionne mais qu’un site web ne fonctionne pas, le problème peut venir du DNS.

### 5. Tester le DNS

```bash
ping google.com
```

ou :

```bash
nslookup google.com
```

Si l’adresse IP répond mais pas le nom de domaine, le problème vient probablement de la résolution DNS.

### 6. Vérifier la route par défaut

Sous Linux :

```bash
ip route
```

Sous Windows :

```powershell
route print
```

La machine doit disposer d’une route par défaut vers la passerelle.

---

## Tableau de diagnostic rapide

| Test | Résultat | Interprétation possible |
|---|---|---|
| Pas d’adresse IP | Échec DHCP | Problème DHCP ou réseau local |
| IP en 169.254.x.x | APIPA | Le poste n’a pas reçu d’adresse DHCP |
| Ping passerelle OK | Réseau local OK | Problème potentiellement externe |
| Ping 8.8.8.8 OK mais site KO | Internet OK | Problème DNS probable |
| Ping domaine KO | DNS KO | Vérifier DNS |
| Aucun ping ne fonctionne | Connexion KO | Vérifier câble, Wi-Fi, carte réseau |

---

## Commandes utiles

### Windows

```powershell
ipconfig
ipconfig /all
ipconfig /release
ipconfig /renew
ipconfig /flushdns
ping 8.8.8.8
nslookup google.com
tracert google.com
```

### Linux

```bash
ip addr
ip route
ping 8.8.8.8
ping google.com
resolvectl status
traceroute google.com
```

---

## Exemple de compte rendu d’incident

Incident : utilisateur sans accès Internet.  
Poste : PC portable Windows.  
Constat : adresse IP en 169.254.x.x.  
Diagnostic : le poste ne reçoit pas d’adresse DHCP.  
Actions : redémarrage carte réseau, test câble, test autre port réseau.  
Résultat : connexion rétablie après changement de câble.  
Prévention : vérifier l’état du câblage et documenter le poste concerné.

---

## Compétences travaillées

- support informatique ;
- diagnostic réseau ;
- TCP/IP ;
- DHCP ;
- DNS ;
- documentation d’incident ;
- résolution méthodique de problème.
