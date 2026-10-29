      *> Rapport du parc informatique par service.
      *> Lit parc.txt (non trie), trie par service avec SORT,
      *> puis ecrit rapport-parc.txt avec un sous total par service.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARC.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-PARC ASSIGN TO "parc.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STATUT-P.
           SELECT F-RAPPORT ASSIGN TO "rapport-parc.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STATUT-R.
      *> Fichier de travail utilise par SORT
           SELECT F-TRI ASSIGN TO "tri.tmp".

       DATA DIVISION.
       FILE SECTION.
       FD  F-PARC.
       01  E-MATERIEL.
           05 E-SERVICE        PIC X(10).
           05 E-INVENTAIRE     PIC X(8).
           05 E-TYPE           PIC X(12).
           05 E-PRIX           PIC 9(5)V99.
           05 E-ANNEE          PIC 9(4).

       SD  F-TRI.
       01  T-MATERIEL.
           05 T-SERVICE        PIC X(10).
           05 T-INVENTAIRE     PIC X(8).
           05 T-TYPE           PIC X(12).
           05 T-PRIX           PIC 9(5)V99.
           05 T-ANNEE          PIC 9(4).

       FD  F-RAPPORT.
       01  R-LIGNE             PIC X(70).

       WORKING-STORAGE SECTION.
       01  WS-STATUT-P         PIC XX.
       01  WS-STATUT-R         PIC XX.
       01  WS-FIN-PARC         PIC X VALUE "N".
           88 FIN-PARC         VALUE "O".
       01  WS-FIN-TRI          PIC X VALUE "N".
           88 FIN-TRI          VALUE "O".

      *> Un materiel de 5 ans ou plus est a renouveler
       01  WS-AGE-MAX          PIC 99 VALUE 5.
       01  WS-DATE-DU-JOUR     PIC X(21).
       01  WS-ANNEE-COURANTE   PIC 9(4).
       01  WS-AGE              PIC 99.
       01  WS-MARQUE           PIC X(12).

      *> Service en cours pour detecter la rupture
       01  WS-SERVICE-PREC     PIC X(10) VALUE SPACES.

      *> Compteurs du service en cours
       01  WS-NB-SERVICE       PIC 9(4).
       01  WS-RENOUV-SERVICE   PIC 9(4).
       01  WS-VALEUR-SERVICE   PIC 9(7)V99.

      *> Compteurs generaux
       01  WS-NB-TOTAL         PIC 9(4) VALUE 0.
       01  WS-RENOUV-TOTAL     PIC 9(4) VALUE 0.
       01  WS-VALEUR-TOTAL     PIC 9(8)V99 VALUE 0.
       01  WS-NB-ERREUR        PIC 9(4) VALUE 0.

      *> Zones d'affichage
       01  WS-ED-PRIX          PIC ZZZZ9.99.
       01  WS-ED-VALEUR        PIC Z(7)9.99.
       01  WS-ED-NB            PIC ZZZ9.
       01  WS-ED-AGE           PIC Z9.
       01  WS-SEPARATEUR       PIC X(70) VALUE ALL "-".

       PROCEDURE DIVISION.
       PRINCIPAL.
           MOVE FUNCTION CURRENT-DATE TO WS-DATE-DU-JOUR
           MOVE WS-DATE-DU-JOUR(1:4) TO WS-ANNEE-COURANTE

           SORT F-TRI
               ON ASCENDING KEY T-SERVICE T-INVENTAIRE
               INPUT PROCEDURE IS VALIDER-ENTREES
               OUTPUT PROCEDURE IS PRODUIRE-RAPPORT

           DISPLAY "Materiels traites  : " WS-NB-TOTAL
           DISPLAY "A renouveler       : " WS-RENOUV-TOTAL
           DISPLAY "Lignes en erreur   : " WS-NB-ERREUR
           MOVE WS-VALEUR-TOTAL TO WS-ED-VALEUR
           DISPLAY "Valeur d'achat     : " WS-ED-VALEUR " EUR"
           STOP RUN.

      *> Etape 1 : on lit parc.txt et on envoie au tri
      *> seulement les lignes valides (RELEASE).
       VALIDER-ENTREES.
           OPEN INPUT F-PARC
           IF WS-STATUT-P NOT = "00"
               DISPLAY "Impossible d'ouvrir parc.txt (statut "
                   WS-STATUT-P ")"
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM LIRE-PARC
           PERFORM UNTIL FIN-PARC
               IF E-PRIX IS NUMERIC AND E-ANNEE IS NUMERIC
                   AND E-SERVICE NOT = SPACES
                   AND E-ANNEE <= WS-ANNEE-COURANTE
                   RELEASE T-MATERIEL FROM E-MATERIEL
               ELSE
                   ADD 1 TO WS-NB-ERREUR
                   DISPLAY "Ligne ignoree (donnees invalides) : "
                       E-INVENTAIRE
               END-IF
               PERFORM LIRE-PARC
           END-PERFORM
           CLOSE F-PARC.

       LIRE-PARC.
           READ F-PARC
               AT END SET FIN-PARC TO TRUE
           END-READ.

      *> Etape 2 : on recupere les lignes triees (RETURN)
      *> et on ecrit le rapport avec rupture sur le service.
       PRODUIRE-RAPPORT.
           OPEN OUTPUT F-RAPPORT
           PERFORM ECRIRE-ENTETE

           PERFORM LIRE-TRI
           PERFORM UNTIL FIN-TRI
               IF T-SERVICE NOT = WS-SERVICE-PREC
                   IF WS-SERVICE-PREC NOT = SPACES
                       PERFORM ECRIRE-SOUS-TOTAL
                   END-IF
                   PERFORM DEBUT-SERVICE
               END-IF
               PERFORM TRAITER-MATERIEL
               PERFORM LIRE-TRI
           END-PERFORM

      *> Le dernier service n'a pas eu de rupture, on le ferme ici
           IF WS-SERVICE-PREC NOT = SPACES
               PERFORM ECRIRE-SOUS-TOTAL
           END-IF
           PERFORM ECRIRE-TOTAL-GENERAL
           CLOSE F-RAPPORT.

       LIRE-TRI.
           RETURN F-TRI
               AT END SET FIN-TRI TO TRUE
           END-RETURN.

       ECRIRE-ENTETE.
           MOVE SPACES TO R-LIGNE
           STRING "RAPPORT DU PARC PAR SERVICE (annee "
               WS-ANNEE-COURANTE ")"
               DELIMITED BY SIZE INTO R-LIGNE
           WRITE R-LIGNE
           MOVE WS-SEPARATEUR TO R-LIGNE
           WRITE R-LIGNE.

       DEBUT-SERVICE.
           MOVE T-SERVICE TO WS-SERVICE-PREC
           MOVE 0 TO WS-NB-SERVICE WS-RENOUV-SERVICE
                     WS-VALEUR-SERVICE
           MOVE SPACES TO R-LIGNE
           STRING "Service : " T-SERVICE
               DELIMITED BY SIZE INTO R-LIGNE
           WRITE R-LIGNE.

       TRAITER-MATERIEL.
           COMPUTE WS-AGE = WS-ANNEE-COURANTE - T-ANNEE
           IF WS-AGE >= WS-AGE-MAX
               MOVE "A RENOUVELER" TO WS-MARQUE
               ADD 1 TO WS-RENOUV-SERVICE
           ELSE
               MOVE SPACES TO WS-MARQUE
           END-IF

           ADD 1 TO WS-NB-SERVICE
           ADD T-PRIX TO WS-VALEUR-SERVICE

           MOVE T-PRIX TO WS-ED-PRIX
           MOVE WS-AGE TO WS-ED-AGE
           MOVE SPACES TO R-LIGNE
           STRING "  " T-INVENTAIRE "  " T-TYPE
               WS-ED-PRIX " EUR  " T-ANNEE " (" WS-ED-AGE " ans)  "
               WS-MARQUE
               DELIMITED BY SIZE INTO R-LIGNE
           WRITE R-LIGNE.

       ECRIRE-SOUS-TOTAL.
           MOVE WS-NB-SERVICE TO WS-ED-NB
           MOVE WS-VALEUR-SERVICE TO WS-ED-VALEUR
           MOVE SPACES TO R-LIGNE
           STRING "  Sous total : " WS-ED-NB " materiel(s), "
               WS-ED-VALEUR " EUR"
               DELIMITED BY SIZE INTO R-LIGNE
           WRITE R-LIGNE
           MOVE WS-RENOUV-SERVICE TO WS-ED-NB
           MOVE SPACES TO R-LIGNE
           STRING "  A renouveler : " WS-ED-NB
               DELIMITED BY SIZE INTO R-LIGNE
           WRITE R-LIGNE
           MOVE SPACES TO R-LIGNE
           WRITE R-LIGNE

      *> On reporte le service dans les totaux generaux
           ADD WS-NB-SERVICE TO WS-NB-TOTAL
           ADD WS-RENOUV-SERVICE TO WS-RENOUV-TOTAL
           ADD WS-VALEUR-SERVICE TO WS-VALEUR-TOTAL.

       ECRIRE-TOTAL-GENERAL.
           MOVE WS-SEPARATEUR TO R-LIGNE
           WRITE R-LIGNE
           MOVE WS-NB-TOTAL TO WS-ED-NB
           MOVE WS-VALEUR-TOTAL TO WS-ED-VALEUR
           MOVE SPACES TO R-LIGNE
           STRING "TOTAL GENERAL : " WS-ED-NB " materiel(s), "
               WS-ED-VALEUR " EUR"
               DELIMITED BY SIZE INTO R-LIGNE
           WRITE R-LIGNE
           MOVE WS-RENOUV-TOTAL TO WS-ED-NB
           MOVE SPACES TO R-LIGNE
           STRING "A renouveler  : " WS-ED-NB
               DELIMITED BY SIZE INTO R-LIGNE
           WRITE R-LIGNE.
