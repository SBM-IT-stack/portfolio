-- Test du trigger : on fait avancer le ticket 17 comme en vrai
-- Attention, ce fichier modifie les données.

PRAGMA foreign_keys = ON;

-- Lucas (N1) prend le ticket
UPDATE ticket SET id_technicien = 1, statut = 'en cours' WHERE id_ticket = 17;

-- Il attend une info de la RH
UPDATE ticket SET statut = 'en attente' WHERE id_ticket = 17;

-- Le compte est créé, le ticket est résolu
UPDATE ticket SET statut = 'resolu' WHERE id_ticket = 17;

-- Ne doit rien ajouter dans l'historique : le statut ne change pas
UPDATE ticket SET statut = 'resolu' WHERE id_ticket = 17;

-- Résultat : 3 lignes d'historique et une date de résolution remplie
SELECT ancien_statut, nouveau_statut, date_changement
FROM historique_statut
WHERE id_ticket = 17
ORDER BY id_historique;

SELECT id_ticket, statut, date_resolution FROM ticket WHERE id_ticket = 17;
