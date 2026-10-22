-- Requêtes de suivi pour une équipe support
-- A lancer après schema.sql et donnees.sql (lecture seule, rien n'est modifié)

-- 1. Tickets encore ouverts, les plus urgents en premier
SELECT id_ticket, titre, priorite, statut, technicien
FROM v_tickets_ouverts
ORDER BY CASE priorite WHEN 'critique' THEN 1 WHEN 'haute' THEN 2
                       WHEN 'normale' THEN 3 ELSE 4 END,
         date_ouverture;

-- 2. Tickets que personne n'a encore pris
SELECT id_ticket, titre, demandeur, date_ouverture
FROM v_tickets_ouverts
WHERE technicien = '(non assigné)';

-- 3. Charge actuelle de chaque technicien (ceux à 0 apparaissent aussi)
SELECT te.prenom || ' ' || te.nom AS technicien, te.niveau,
       COUNT(t.id_ticket) AS tickets_ouverts
FROM technicien te
LEFT JOIN ticket t ON t.id_technicien = te.id_technicien
                  AND t.statut NOT IN ('resolu', 'clos')
GROUP BY te.id_technicien
ORDER BY tickets_ouverts DESC;

-- 4. Nombre de tickets et délai moyen de résolution par catégorie
SELECT categorie, COUNT(*) AS nb_resolus, ROUND(AVG(heures), 1) AS heures_moyennes
FROM v_delais
GROUP BY categorie
ORDER BY heures_moyennes DESC;

-- 5. Taux de respect du SLA par priorité
SELECT priorite,
       COUNT(*) AS nb_tickets,
       SUM(CASE WHEN respect_sla = 'ok' THEN 1 ELSE 0 END) AS dans_les_temps,
       CAST(ROUND(100.0 * SUM(CASE WHEN respect_sla = 'ok' THEN 1 ELSE 0 END) / COUNT(*)) AS INTEGER) AS pourcentage
FROM v_delais
GROUP BY priorite;

-- 6. Tickets résolus hors délai : ceux dont il faut parler en réunion d'équipe
SELECT id_ticket, titre, priorite, heures, delai_heures
FROM v_delais
WHERE respect_sla = 'hors delai'
ORDER BY heures - delai_heures DESC;

-- 7. Utilisateurs qui ouvrent souvent des tickets (3 ou plus)
SELECT d.prenom || ' ' || d.nom AS demandeur, d.service, COUNT(*) AS nb_tickets
FROM ticket t
JOIN demandeur d ON d.id_demandeur = t.id_demandeur
GROUP BY d.id_demandeur
HAVING COUNT(*) >= 3
ORDER BY nb_tickets DESC;

-- 8. Problèmes récurrents : même catégorie pour le même demandeur
SELECT d.prenom || ' ' || d.nom AS demandeur, c.nom AS categorie, COUNT(*) AS nb
FROM ticket t
JOIN demandeur d ON d.id_demandeur = t.id_demandeur
JOIN categorie c ON c.id_categorie = t.id_categorie
GROUP BY t.id_demandeur, t.id_categorie
HAVING COUNT(*) >= 2;

-- 9. Part des tickets escaladés au N2, par catégorie
SELECT c.nom AS categorie, COUNT(*) AS total, SUM(t.escalade_n2) AS escalades
FROM ticket t
JOIN categorie c ON c.id_categorie = t.id_categorie
GROUP BY c.id_categorie
ORDER BY escalades DESC;

-- 10. Nombre de tickets par service : quel service sollicite le plus le support
SELECT service, COUNT(*) AS nb_tickets
FROM ticket t
JOIN demandeur d ON d.id_demandeur = t.id_demandeur
GROUP BY service
ORDER BY nb_tickets DESC;

-- 11. Tickets plus longs que la moyenne de leur catégorie (sous-requête corrélée)
SELECT v.id_ticket, v.titre, v.categorie, v.heures
FROM v_delais v
WHERE v.heures > (SELECT AVG(v2.heures) FROM v_delais v2 WHERE v2.categorie = v.categorie);
