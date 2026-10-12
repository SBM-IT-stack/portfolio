# domotique-dashboard

Un tableau de bord web de simulation domotique : suivi de température/humidité par pièce,
interrupteurs pour l'éclairage et les prises, graphique de consommation électrique.

C'est une **démo front-end autonome** (un seul fichier `index.html`, aucune dépendance,
aucun backend) : les données sont générées aléatoirement côté navigateur pour simuler
des capteurs. L'objectif est de poser les bases visuelles et l'architecture d'une
interface domotique, avant de la brancher un jour sur du matériel réel.

## Aperçu

- 4 pièces (Salon, Chambre, Cuisine, Garage) avec température/humidité simulées,
  mises à jour toutes les 3 secondes
- Interrupteurs éclairage + une prise dédiée par pièce (dont une prise IRVE dans le garage)
- Graphique de consommation électrique sur 12h (simulé)

## Lancer la démo

Aucune installation : ouvrir directement `index.html` dans un navigateur.

## Pourquoi ce projet

Fait le lien entre l'intérêt pour l'électricité/le photovoltaïque/l'IRVE et le
développement web : c'est le genre d'interface qu'on retrouve derrière un vrai
projet domotique (Home Assistant, Jeedom...).

## Prochaines étapes possibles (pour en faire un vrai projet matériel)

- [ ] Remplacer les données simulées par de vraies lectures de capteurs
      (ESP32 + DHT22 pour température/humidité, envoyées en MQTT ou HTTP)
- [ ] Ajouter un petit backend (Python/Flask ou Node.js) qui reçoit les données des capteurs
- [ ] Piloter réellement un relais (éclairage) depuis l'interface via un microcontrôleur
