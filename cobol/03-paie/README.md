# Calcul de paie simple en COBOL

## Ce que ça fait

Le programme lit un fichier d'employés (`employes.txt`), calcule pour chacun le salaire brut, les cotisations et le salaire net, puis écrit un bulletin par employé dans `bulletins.txt`. À la fin, il affiche le nombre de bulletins générés, les lignes rejetées et la masse salariale.

Les heures sont découpées en trois tranches :

- jusqu'à 151,67 h (35 h par semaine) : taux normal
- de 151,67 h à 186,33 h : heures sup. majorées de 25 %
- au delà : heures sup. majorées de 50 %

Les cotisations sont un taux unique de 22 % du brut. C'est volontairement simplifié : une vraie fiche de paie a des dizaines de lignes (URSSAF, retraite, CSG, plafonds...), le but ici était de travailler la logique, pas le droit social.

## Pourquoi je l'ai fait

C'est mon troisième exercice COBOL. Après le calcul de moyenne et la lecture d'un fichier de clients, je voulais combiner lecture de fichier, calculs décimaux et écriture d'un rapport. La paie est un cas typique de traitement batch en COBOL, c'est encore ce qui tourne dans beaucoup de banques, d'assurances et d'administrations.

## Format du fichier d'entrée

Une ligne par employé, en largeur fixe (35 caractères) :

| Position | Champ | Exemple |
|---|---|---|
| 1 à 5 | matricule | `00001` |
| 6 à 25 | nom | `DUPONT Marie` (complété par des espaces) |
| 26 à 30 | taux horaire, 2 décimales implicites | `01250` = 12,50 EUR |
| 31 à 35 | heures du mois, 2 décimales implicites | `15167` = 151,67 h |

Une ligne dont le taux ou les heures ne sont pas numériques est ignorée et comptée en erreur (la ligne 5 du fichier d'exemple est là pour tester ça).

## Utilisation

```bash
sudo apt install gnucobol
cobc -x paie.cob -o paie
./paie
cat bulletins.txt
```

Sortie console avec le fichier d'exemple :

```
Ligne ignoree (donnees invalides) : 00005
Bulletins generes : 0004
Lignes en erreur  : 0001
Masse salariale brute :     8562.05 EUR
Total net verse       :     6678.40 EUR
```

Extrait de `bulletins.txt` :

```
Matricule : 00002   MARTIN Lucas
Heures travaillees  : 160.00
  dont sup. a 25 %  :   8.33
  dont sup. a 50 %  :   0.00
Salaire brut        :   1912.57 EUR
Cotisations (22 %)  :    420.77 EUR
Salaire net         :   1491.80 EUR
```

J'ai vérifié les montants à la main (et avec un petit calcul Python) pour les quatre employés.

## Ce que je voudrais ajouter

- des primes et des retenues (absences, tickets resto) lues dans un deuxième fichier
- un fichier de paramètres pour les taux au lieu de les avoir en dur dans le programme
- un tri des employés par service avec un sous total par service

## Testé sur

Ubuntu 24.04 avec GnuCOBOL 3.1.2, en format fixe (colonnes 8 à 72).
