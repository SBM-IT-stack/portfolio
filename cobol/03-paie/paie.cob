      *> Calcul de paie simple a partir d'un fichier d'employes.
      *> Lit employes.txt, ecrit bulletins.txt.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAIE.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-EMPLOYES ASSIGN TO "employes.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STATUT-E.
           SELECT F-BULLETINS ASSIGN TO "bulletins.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STATUT-B.

       DATA DIVISION.
       FILE SECTION.
       FD  F-EMPLOYES.
       01  E-EMPLOYE.
           05 E-MATRICULE      PIC X(5).
           05 E-NOM            PIC X(20).
           05 E-TAUX           PIC 9(3)V99.
           05 E-HEURES         PIC 9(3)V99.

       FD  F-BULLETINS.
       01  B-LIGNE             PIC X(60).

       WORKING-STORAGE SECTION.
       01  WS-STATUT-E         PIC XX.
       01  WS-STATUT-B         PIC XX.
       01  WS-FIN              PIC X VALUE "N".
           88 FIN-FICHIER      VALUE "O".

      *> Parametres de calcul (simplifies, voir README)
       01  WS-HEURES-LEGALES   PIC 9(3)V99 VALUE 151.67.
       01  WS-SEUIL-50         PIC 9(3)V99 VALUE 186.33.
       01  WS-TAUX-COTIS       PIC V99     VALUE 0.22.

       01  WS-H-NORMALES       PIC 9(3)V99.
       01  WS-H-SUP25          PIC 9(3)V99.
       01  WS-H-SUP50          PIC 9(3)V99.
       01  WS-BRUT             PIC 9(6)V99.
       01  WS-COTIS            PIC 9(6)V99.
       01  WS-NET              PIC 9(6)V99.

       01  WS-NB-OK            PIC 9(4) VALUE 0.
       01  WS-NB-ERREUR        PIC 9(4) VALUE 0.
       01  WS-TOTAL-BRUT       PIC 9(8)V99 VALUE 0.
       01  WS-TOTAL-NET        PIC 9(8)V99 VALUE 0.

      *> Zones d'affichage (format lisible)
       01  WS-ED-MONTANT       PIC Z(5)9.99.
       01  WS-ED-TOTAL         PIC Z(7)9.99.
       01  WS-ED-HEURES        PIC ZZ9.99.
       01  WS-SEPARATEUR       PIC X(60) VALUE ALL "-".

       PROCEDURE DIVISION.
       PRINCIPAL.
           OPEN INPUT F-EMPLOYES
           IF WS-STATUT-E NOT = "00"
               DISPLAY "Impossible d'ouvrir employes.txt (statut "
                   WS-STATUT-E ")"
               STOP RUN
           END-IF
           OPEN OUTPUT F-BULLETINS

           PERFORM LIRE-EMPLOYE
           PERFORM UNTIL FIN-FICHIER
               IF E-TAUX IS NUMERIC AND E-HEURES IS NUMERIC
                   PERFORM CALCULER-PAIE
                   PERFORM ECRIRE-BULLETIN
               ELSE
                   ADD 1 TO WS-NB-ERREUR
                   DISPLAY "Ligne ignoree (donnees invalides) : "
                       E-MATRICULE
               END-IF
               PERFORM LIRE-EMPLOYE
           END-PERFORM

           PERFORM AFFICHER-TOTAUX
           CLOSE F-EMPLOYES F-BULLETINS
           STOP RUN.

       LIRE-EMPLOYE.
           READ F-EMPLOYES
               AT END SET FIN-FICHIER TO TRUE
           END-READ.

       CALCULER-PAIE.
      *> Repartition des heures en trois tranches
           MOVE 0 TO WS-H-SUP25 WS-H-SUP50
           IF E-HEURES > WS-HEURES-LEGALES
               MOVE WS-HEURES-LEGALES TO WS-H-NORMALES
               IF E-HEURES > WS-SEUIL-50
                   COMPUTE WS-H-SUP25 = WS-SEUIL-50 - WS-HEURES-LEGALES
                   COMPUTE WS-H-SUP50 = E-HEURES - WS-SEUIL-50
               ELSE
                   COMPUTE WS-H-SUP25 = E-HEURES - WS-HEURES-LEGALES
               END-IF
           ELSE
               MOVE E-HEURES TO WS-H-NORMALES
           END-IF

           COMPUTE WS-BRUT ROUNDED =
                 WS-H-NORMALES * E-TAUX
               + WS-H-SUP25 * E-TAUX * 1.25
               + WS-H-SUP50 * E-TAUX * 1.50
           COMPUTE WS-COTIS ROUNDED = WS-BRUT * WS-TAUX-COTIS
           COMPUTE WS-NET = WS-BRUT - WS-COTIS

           ADD 1 TO WS-NB-OK
           ADD WS-BRUT TO WS-TOTAL-BRUT
           ADD WS-NET TO WS-TOTAL-NET.

       ECRIRE-BULLETIN.
           MOVE WS-SEPARATEUR TO B-LIGNE
           WRITE B-LIGNE

           MOVE SPACES TO B-LIGNE
           STRING "Matricule : " E-MATRICULE "   " E-NOM
               DELIMITED BY SIZE INTO B-LIGNE
           WRITE B-LIGNE

           MOVE E-HEURES TO WS-ED-HEURES
           MOVE SPACES TO B-LIGNE
           STRING "Heures travaillees  : " WS-ED-HEURES
               DELIMITED BY SIZE INTO B-LIGNE
           WRITE B-LIGNE

           MOVE WS-H-SUP25 TO WS-ED-HEURES
           MOVE SPACES TO B-LIGNE
           STRING "  dont sup. a 25 %  : " WS-ED-HEURES
               DELIMITED BY SIZE INTO B-LIGNE
           WRITE B-LIGNE

           MOVE WS-H-SUP50 TO WS-ED-HEURES
           MOVE SPACES TO B-LIGNE
           STRING "  dont sup. a 50 %  : " WS-ED-HEURES
               DELIMITED BY SIZE INTO B-LIGNE
           WRITE B-LIGNE

           MOVE WS-BRUT TO WS-ED-MONTANT
           MOVE SPACES TO B-LIGNE
           STRING "Salaire brut        : " WS-ED-MONTANT " EUR"
               DELIMITED BY SIZE INTO B-LIGNE
           WRITE B-LIGNE

           MOVE WS-COTIS TO WS-ED-MONTANT
           MOVE SPACES TO B-LIGNE
           STRING "Cotisations (22 %)  : " WS-ED-MONTANT " EUR"
               DELIMITED BY SIZE INTO B-LIGNE
           WRITE B-LIGNE

           MOVE WS-NET TO WS-ED-MONTANT
           MOVE SPACES TO B-LIGNE
           STRING "Salaire net         : " WS-ED-MONTANT " EUR"
               DELIMITED BY SIZE INTO B-LIGNE
           WRITE B-LIGNE.

       AFFICHER-TOTAUX.
           DISPLAY "Bulletins generes : " WS-NB-OK
           DISPLAY "Lignes en erreur  : " WS-NB-ERREUR
           MOVE WS-TOTAL-BRUT TO WS-ED-TOTAL
           DISPLAY "Masse salariale brute : " WS-ED-TOTAL " EUR"
           MOVE WS-TOTAL-NET TO WS-ED-TOTAL
           DISPLAY "Total net verse       : " WS-ED-TOTAL " EUR".
