# Lecture d'un fichier séquentiel de clients (COBOL)

## Ce que ça fait

Le programme lit `clients.dat`, un fichier texte où chaque ligne est un client avec une largeur fixe de 47 caractères. Il affiche la liste des clients avec leur solde, marque ceux qui sont débiteurs (solde négatif), puis affiche un bilan : nombre de clients lus, nombre de débiteurs et total des soldes.

Format d'une ligne :

| Position | Champ | Format |
|---|---|---|
| 1 à 4 | Identifiant | 4 chiffres |
| 5 à 24 | Nom | 20 caractères |
| 25 à 39 | Ville | 15 caractères |
| 40 à 47 | Solde | signe + 7 chiffres, les 2 derniers sont les centimes |

Exemple : `0002MARTIN              PARIS          -0004200` donne un solde de -42,00.

## Pourquoi je l'ai fait

Après le calcul de moyenne, je voulais passer à ce que le COBOL fait vraiment en entreprise : lire des fichiers d'enregistrements à largeur fixe. C'est aussi le genre de fichier qu'on récupère encore dans des exports d'anciens logiciels de gestion.

## Comment l'utiliser

```bash
sudo apt install gnucobol
cobc -x clients.cob -o clients
./clients
```

Le fichier `clients.dat` doit être dans le dossier courant. S'il est absent, le programme affiche le code d'erreur (35 = fichier introuvable) au lieu de planter.

Exemple de sortie :

```
ID   NOM                  VILLE              SOLDE
----------------------------------------------------------
0001 DUPONT               LYON              1250,50
0002 MARTIN               PARIS              -42,00 DEBITEUR
...
Clients lus      :    6
Clients debiteurs:    2
Total des soldes :     4637,35
```

## Ce que je voudrais ajouter

- écrire les clients débiteurs dans un second fichier au lieu de seulement les afficher
- vérifier que le solde est bien numérique avant de l'additionner
- un tri par ville avec l'instruction `SORT`

## Testé sur

Ubuntu 24.04 avec GnuCOBOL 3.1.2. Testé avec le fichier fourni, sans fichier (erreur 35) et avec un fichier vide.
