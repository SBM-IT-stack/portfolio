      *> Lecture d'un fichier sequentiel de clients
      *> Affiche la liste, le total des soldes et les clients debiteurs
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CLIENTS.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *> Virgule decimale a la francaise pour l'affichage
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-CLIENTS ASSIGN TO "clients.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-STATUT.

       DATA DIVISION.
       FILE SECTION.
      *> Un enregistrement = une ligne de 47 caracteres
       FD  F-CLIENTS.
       01  ENR-CLIENT.
           05 CLI-ID          PIC 9(4).
           05 CLI-NOM         PIC X(20).
           05 CLI-VILLE       PIC X(15).
           05 CLI-SOLDE       PIC S9(5)V99 SIGN LEADING SEPARATE.

       WORKING-STORAGE SECTION.
       01  WS-STATUT          PIC XX.
       01  WS-FIN             PIC X VALUE "N".
           88 FIN-FICHIER     VALUE "O".

       01  WS-NB-CLIENTS      PIC 9(4) VALUE 0.
       01  WS-NB-DEBITEURS    PIC 9(4) VALUE 0.
       01  WS-TOTAL           PIC S9(7)V99 VALUE 0.

      *> Zones d'affichage (le V99 ne s'affiche pas tel quel)
       01  WS-SOLDE-ED        PIC -----9,99.
       01  WS-TOTAL-ED        PIC -------9,99.
       01  WS-NB-ED           PIC ZZZ9.
       01  WS-MENTION         PIC X(9).

       PROCEDURE DIVISION.
       PRINCIPAL.
           OPEN INPUT F-CLIENTS
           IF WS-STATUT NOT = "00"
               DISPLAY "Erreur ouverture clients.dat, statut "
                       WS-STATUT
               STOP RUN
           END-IF

           DISPLAY "ID   NOM                  VILLE          "
                   "    SOLDE"
           DISPLAY "---------------------------------------"
                   "-------------------"

           PERFORM LIRE-CLIENT
           PERFORM UNTIL FIN-FICHIER
               PERFORM TRAITER-CLIENT
               PERFORM LIRE-CLIENT
           END-PERFORM

           CLOSE F-CLIENTS
           PERFORM AFFICHER-BILAN
           STOP RUN.

       LIRE-CLIENT.
           READ F-CLIENTS
               AT END SET FIN-FICHIER TO TRUE
           END-READ.

       TRAITER-CLIENT.
           ADD 1 TO WS-NB-CLIENTS
           ADD CLI-SOLDE TO WS-TOTAL
           MOVE SPACES TO WS-MENTION
           IF CLI-SOLDE < 0
               ADD 1 TO WS-NB-DEBITEURS
               MOVE "DEBITEUR" TO WS-MENTION
           END-IF
           MOVE CLI-SOLDE TO WS-SOLDE-ED
           DISPLAY CLI-ID " " CLI-NOM " " CLI-VILLE " "
                   WS-SOLDE-ED " " WS-MENTION.

       AFFICHER-BILAN.
           DISPLAY " "
           MOVE WS-NB-CLIENTS TO WS-NB-ED
           DISPLAY "Clients lus      : " WS-NB-ED
           MOVE WS-NB-DEBITEURS TO WS-NB-ED
           DISPLAY "Clients debiteurs: " WS-NB-ED
           MOVE WS-TOTAL TO WS-TOTAL-ED
           DISPLAY "Total des soldes : " WS-TOTAL-ED.
