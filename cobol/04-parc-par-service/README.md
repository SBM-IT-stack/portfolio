# Rapport du parc informatique par service en COBOL

## Ce que ça fait

Le programme lit un fichier d'inventaire du parc (`parc.txt`), dans lequel les lignes sont dans le désordre. Il trie les matériels par service avec l'instruction `SORT`, puis écrit un rapport (`rapport-parc.txt`) avec :

- la liste des matériels de chaque service, avec leur âge
- un sous total par service (nombre de matériels, valeur d'achat, nombre à renouveler)
- un total général à la fin

Un matériel est marqué « A RENOUVELER » quand il a 5 ans ou plus. L'année de référence est l'année en cours, lue avec `FUNCTION CURRENT-DATE`.

## Pourquoi je l'ai fait

C'est mon quatrième exercice COBOL. Dans le projet de paie, j'avais noté que je voulais faire un tri par service avec des sous totaux. C'est ce qu'on appelle une rupture de séquence (ou rupture de niveau) : on parcourt un fichier trié et on écrit un sous total à chaque fois que la clé change. C'est un classique des traitements batch, et ça m'a obligé à apprendre le `SORT` avec `INPUT PROCEDURE` et `OUTPUT PROCEDURE`.

J'ai pris un inventaire de parc parce que c'est un sujet que je connais déjà côté support (j'ai fait la même chose en SQL dans `sql/inventaire-parc`).

## Format du fichier d'entrée

Une ligne par matériel, en largeur fixe (41 caractères) :

| Position | Champ | Exemple |
|---|---|---|
| 1 à 10 | service | `COMPTA` (complété par des espaces) |
| 11 à 18 | numéro d'inventaire | `PC-00012` |
| 19 à 30 | type | `PORTABLE` |
| 31 à 37 | prix d'achat, 2 décimales implicites | `0089900` = 899,00 EUR |
| 38 à 41 | année d'achat | `2023` |

Une ligne est ignorée et comptée en erreur si le prix ou l'année ne sont pas numériques, si le service est vide ou si l'année est dans le futur. La ligne `PC-00032` du fichier d'exemple est là pour tester ça.

## Utilisation

```bash
sudo apt install gnucobol
cobc -x parc.cob -o parc
./parc
cat rapport-parc.txt
```

Sortie console avec le fichier d'exemple (en 2026) :

```
Ligne ignoree (donnees invalides) : PC-00032
Materiels traites  : 0011
A renouveler       : 0007
Lignes en erreur   : 0001
Valeur d'achat     :    10421.00 EUR
```

Extrait de `rapport-parc.txt` :

```
Service : COMPTA
  ECR-0010  ECRAN         159.00 EUR  2024 ( 2 ans)
  IMP-0003  IMPRIMANTE    399.00 EUR  2016 (10 ans)  A RENOUVELER
  PC-00012  PORTABLE      899.00 EUR  2023 ( 3 ans)
  PC-00013  FIXE          599.00 EUR  2017 ( 9 ans)  A RENOUVELER
  Sous total :    4 materiel(s),     2056.00 EUR
  A renouveler :    2
```

Si `parc.txt` est absent, le programme affiche le statut du fichier (35) et se termine avec le code retour 1.

## Ce que je voudrais ajouter

- un deuxième niveau de rupture (par service puis par type de matériel)
- la durée de renouvellement par type dans un fichier de paramètres (un serveur ne se remplace pas au même rythme qu'un écran)
- un fichier de sortie à part avec seulement les matériels à renouveler, pour préparer un budget

## Testé sur

Ubuntu 24.04 avec GnuCOBOL 3.1.2, en format fixe (colonnes 8 à 72). J'ai vérifié les totaux avec une commande awk sur le fichier d'entrée, et testé un fichier vide, un fichier absent et une année dans le futur.
