-- Requêtes utiles pour un technicien qui gère le parc
-- A lancer après schema.sql et donnees.sql

-- 1. Liste des postes en service avec leur utilisateur et son service
SELECT p.nom_machine, p.type, u.prenom || ' ' || u.nom AS utilisateur, s.nom AS service
FROM poste p
JOIN utilisateur u ON u.id_utilisateur = p.id_utilisateur
JOIN service s ON s.id_service = u.id_service
WHERE p.etat = 'en service'
ORDER BY s.nom, p.nom_machine;

-- 2. Postes sans utilisateur (stock, panne...) : LEFT JOIN + IS NULL
SELECT p.nom_machine, p.etat
FROM poste p
LEFT JOIN utilisateur u ON u.id_utilisateur = p.id_utilisateur
WHERE u.id_utilisateur IS NULL;

-- 3. Nombre de postes par service (les services sans poste apparaissent avec 0)
SELECT s.nom AS service, COUNT(p.id_poste) AS nb_postes
FROM service s
LEFT JOIN utilisateur u ON u.id_service = s.id_service
LEFT JOIN poste p ON p.id_utilisateur = u.id_utilisateur
GROUP BY s.nom
ORDER BY nb_postes DESC;

-- 4. Postes encore sous Windows 10 (plus de mises à jour depuis octobre 2025)
SELECT nom_machine, os, ram_go, etat
FROM poste
WHERE os = 'Windows 10' AND etat <> 'reforme';

-- 5. Postes avec moins de 8 Go de RAM (candidats à un remplacement)
SELECT nom_machine, ram_go
FROM poste
WHERE ram_go < 8;

-- 6. Garanties terminées ou qui finissent dans les 6 prochains mois
SELECT nom_machine, fin_garantie,
       CASE WHEN fin_garantie < date('now') THEN 'terminee' ELSE 'bientot' END AS statut
FROM poste
WHERE fin_garantie <= date('now', '+6 months')
ORDER BY fin_garantie;

-- 7. Postes de plus de 5 ans
SELECT nom_machine, date_achat
FROM poste
WHERE date_achat <= date('now', '-5 years')
ORDER BY date_achat;

-- 8. Logiciels installés sur un poste donné
SELECT l.nom, i.version, i.date_install
FROM installation i
JOIN logiciel l ON l.id_logiciel = i.id_logiciel
JOIN poste p ON p.id_poste = i.id_poste
WHERE p.nom_machine = 'PC-INFO-01';

-- 9. Postes en service sans antivirus : NOT EXISTS
SELECT p.nom_machine
FROM poste p
WHERE p.etat = 'en service'
  AND NOT EXISTS (
      SELECT 1
      FROM installation i
      JOIN logiciel l ON l.id_logiciel = i.id_logiciel
      WHERE i.id_poste = p.id_poste AND l.nom LIKE 'Antivirus%'
  );

-- 10. Licences : installations comparées aux licences achetées
SELECT l.nom, l.nb_licences, COUNT(i.id_poste) AS nb_installs,
       CASE WHEN COUNT(i.id_poste) > l.nb_licences THEN 'DEPASSEMENT' ELSE 'ok' END AS statut
FROM logiciel l
LEFT JOIN installation i ON i.id_logiciel = l.id_logiciel
WHERE l.nb_licences IS NOT NULL
GROUP BY l.id_logiciel;

-- 11. Mise à jour : on attribue le poste en stock à Ines Garcia (RH)
UPDATE poste
SET id_utilisateur = (SELECT id_utilisateur FROM utilisateur WHERE login = 'igarcia'),
    etat = 'en service'
WHERE nom_machine = 'PC-STOCK-01';

-- 12. Le poste en panne n'est plus réparable : on le passe en réforme
UPDATE poste SET etat = 'reforme' WHERE nom_machine = 'PC-RH-02';
