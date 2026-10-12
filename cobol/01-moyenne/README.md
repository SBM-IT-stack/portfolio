# 01-moyenne

Mon premier programme en COBOL : on saisit des notes sur 20, il affiche la moyenne, la note la plus basse, la plus haute et la mention.

Je me suis mis au COBOL parce qu'il tourne encore dans beaucoup de banques, d'assurances et d'administrations, et qu'on manque de gens qui savent le lire. Le sujet est simple exprès : je voulais d'abord comprendre la structure d'un programme (les 4 divisions, les PIC, PERFORM, EVALUATE) avant de passer aux fichiers.

## Ce que ça fait

- demande le nombre de notes (entre 1 et 30)
- demande chaque note et redemande tant qu'elle n'est pas entre 0 et 20
- accepte `15.5` comme `15,5`
- calcule la moyenne arrondie à 2 décimales, le min, le max et la mention (Passable à partir de 10, Assez bien 12, Bien 14, Très bien 16)

## Compiler et lancer

Il faut GnuCOBOL (`sudo apt install gnucobol` sous Debian/Ubuntu).

```bash
cobc -x moyenne.cob
./moyenne
```

Exemple :

```
=== Calcul de moyenne ===
Nombre de notes (1 a 30) : 3
Note 01 : 12
Note 02 : 15,5
Note 03 : 9

Moyenne    : 12.17 / 20
Note min   :  9.00
Note max   : 15.50
Mention    : Assez bien
```

## Ce que j'ai appris en le faisant

Au début j'avais mis `PIC Z9,99` pour afficher la moyenne avec une virgule à la française, et j'obtenais `0,12` au lieu de `12,17`. En COBOL, sans `DECIMAL-POINT IS COMMA`, la virgule dans un PIC d'édition est juste un séparateur, pas la virgule décimale. Je suis repassé au point.

## Ce que je voudrais ajouter

- lire les notes depuis un fichier au lieu de les taper (prochain exercice)
- gérer des coefficients
- passer en `DECIMAL-POINT IS COMMA` pour afficher les virgules proprement

## Testé sur

GnuCOBOL 3.1.2, Ubuntu.
