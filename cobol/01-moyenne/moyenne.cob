      *> moyenne.cob
      *> Demande des notes sur 20, puis affiche la moyenne,
      *> la note la plus basse, la plus haute et la mention.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOYENNE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-NB-NOTES      PIC 99       VALUE 0.
       01 WS-I             PIC 99       VALUE 0.
       01 WS-SAISIE        PIC X(10).
       01 WS-NOTE          PIC 99V99    VALUE 0.
       01 WS-TOTAL         PIC 9(4)V99  VALUE 0.
       01 WS-MOYENNE       PIC 99V99    VALUE 0.
       01 WS-MIN           PIC 99V99    VALUE 20.
       01 WS-MAX           PIC 99V99    VALUE 0.
       01 WS-MENTION       PIC X(15).
       01 WS-VALIDE        PIC X        VALUE "N".

      *> zones d'affichage (sans les zeros inutiles devant)
       01 WS-AFF-MOY       PIC Z9.99.
       01 WS-AFF-MIN       PIC Z9.99.
       01 WS-AFF-MAX       PIC Z9.99.

       PROCEDURE DIVISION.
       DEBUT.
           DISPLAY "=== Calcul de moyenne ==="

           PERFORM UNTIL WS-NB-NOTES > 0 AND WS-NB-NOTES <= 30
               DISPLAY "Nombre de notes (1 a 30) : " WITH NO ADVANCING
               ACCEPT WS-SAISIE
               IF FUNCTION TEST-NUMVAL(WS-SAISIE) = 0
                   COMPUTE WS-NB-NOTES = FUNCTION NUMVAL(WS-SAISIE)
               END-IF
               IF WS-NB-NOTES = 0 OR WS-NB-NOTES > 30
                   DISPLAY "Saisie invalide, recommence."
                   MOVE 0 TO WS-NB-NOTES
               END-IF
           END-PERFORM

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-NB-NOTES
               PERFORM SAISIR-NOTE
               ADD WS-NOTE TO WS-TOTAL
               IF WS-NOTE < WS-MIN
                   MOVE WS-NOTE TO WS-MIN
               END-IF
               IF WS-NOTE > WS-MAX
                   MOVE WS-NOTE TO WS-MAX
               END-IF
           END-PERFORM

           COMPUTE WS-MOYENNE ROUNDED = WS-TOTAL / WS-NB-NOTES

           EVALUATE TRUE
               WHEN WS-MOYENNE >= 16
                   MOVE "Tres bien" TO WS-MENTION
               WHEN WS-MOYENNE >= 14
                   MOVE "Bien" TO WS-MENTION
               WHEN WS-MOYENNE >= 12
                   MOVE "Assez bien" TO WS-MENTION
               WHEN WS-MOYENNE >= 10
                   MOVE "Passable" TO WS-MENTION
               WHEN OTHER
                   MOVE "Pas de mention" TO WS-MENTION
           END-EVALUATE

           MOVE WS-MOYENNE TO WS-AFF-MOY
           MOVE WS-MIN TO WS-AFF-MIN
           MOVE WS-MAX TO WS-AFF-MAX

           DISPLAY " "
           DISPLAY "Moyenne    : " WS-AFF-MOY " / 20"
           DISPLAY "Note min   : " WS-AFF-MIN
           DISPLAY "Note max   : " WS-AFF-MAX
           DISPLAY "Mention    : " WS-MENTION
           STOP RUN.

      *> redemande la note tant qu'elle n'est pas entre 0 et 20
       SAISIR-NOTE.
           MOVE "N" TO WS-VALIDE
           PERFORM UNTIL WS-VALIDE = "O"
               DISPLAY "Note " WS-I " : " WITH NO ADVANCING
               ACCEPT WS-SAISIE
               INSPECT WS-SAISIE REPLACING ALL "," BY "."
               IF FUNCTION TEST-NUMVAL(WS-SAISIE) = 0
                   AND FUNCTION NUMVAL(WS-SAISIE) >= 0
                   AND FUNCTION NUMVAL(WS-SAISIE) <= 20
                   COMPUTE WS-NOTE = FUNCTION NUMVAL(WS-SAISIE)
                   MOVE "O" TO WS-VALIDE
               ELSE
                   DISPLAY "Note invalide (entre 0 et 20)."
               END-IF
           END-PERFORM.
