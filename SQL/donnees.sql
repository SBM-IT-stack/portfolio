-- Jeu de données fictif pour tester les requêtes

PRAGMA foreign_keys = ON;

INSERT INTO service (id_service, nom, etage) VALUES
(1, 'Comptabilite', 1),
(2, 'Ressources humaines', 1),
(3, 'Commercial', 2),
(4, 'Informatique', 0),
(5, 'Direction', 3);

INSERT INTO utilisateur (id_utilisateur, nom, prenom, login, id_service) VALUES
(1, 'Martin',  'Claire',  'cmartin',  1),
(2, 'Bernard', 'Lucas',   'lbernard', 1),
(3, 'Petit',   'Sarah',   'spetit',   2),
(4, 'Durand',  'Hugo',    'hdurand',  3),
(5, 'Leroy',   'Emma',    'eleroy',   3),
(6, 'Moreau',  'Nathan',  'nmoreau',  3),
(7, 'Simon',   'Julie',   'jsimon',   4),
(8, 'Laurent', 'Paul',    'plaurent', 5),
(9, 'Garcia',  'Ines',    'igarcia',  2);

INSERT INTO poste (id_poste, nom_machine, type, marque, modele, num_serie, os, ram_go, adresse_ip, date_achat, fin_garantie, etat, id_utilisateur) VALUES
(1,  'PC-COMPTA-01', 'fixe',     'Dell',   'OptiPlex 7010',  'DL7010A1', 'Windows 11', 16, '192.168.10.11', '2023-03-15', '2026-03-15', 'en service', 1),
(2,  'PC-COMPTA-02', 'fixe',     'Dell',   'OptiPlex 3050',  'DL3050B7', 'Windows 10', 8,  '192.168.10.12', '2018-09-01', '2021-09-01', 'en service', 2),
(3,  'PC-RH-01',     'fixe',     'HP',     'ProDesk 400 G9', 'HP400C22', 'Windows 11', 16, '192.168.10.21', '2024-01-10', '2027-01-10', 'en service', 3),
(4,  'PT-COM-01',    'portable', 'Lenovo', 'ThinkPad E14',   'LNE14D01', 'Windows 11', 16, NULL,            '2024-06-20', '2026-12-20', 'en service', 4),
(5,  'PT-COM-02',    'portable', 'Lenovo', 'ThinkPad E14',   'LNE14D02', 'Windows 11', 16, NULL,            '2024-06-20', '2026-12-20', 'en service', 5),
(6,  'PT-COM-03',    'portable', 'HP',     'ProBook 450 G5', 'HP450E09', 'Windows 10', 4,  NULL,            '2019-02-11', '2021-02-11', 'en service', 6),
(7,  'PC-INFO-01',   'fixe',     'Dell',   'OptiPlex 7010',  'DL7010A2', 'Windows 11', 32, '192.168.10.41', '2023-03-15', '2026-03-15', 'en service', 7),
(8,  'PT-DIR-01',    'portable', 'Dell',   'Latitude 5440',  'DL5440F3', 'Windows 11', 16, NULL,            '2025-05-05', '2028-05-05', 'en service', 8),
(9,  'PC-STOCK-01',  'fixe',     'HP',     'ProDesk 400 G9', 'HP400C23', 'Windows 11', 8,  NULL,            '2024-01-10', '2027-01-10', 'stock',      NULL),
(10, 'PC-RH-02',     'fixe',     'HP',     'ProDesk 600 G3', 'HP600G31', 'Windows 10', 8,  '192.168.10.22', '2017-11-30', '2020-11-30', 'panne',      NULL);

INSERT INTO logiciel (id_logiciel, nom, editeur, nb_licences) VALUES
(1, 'Microsoft 365',   'Microsoft', 8),
(2, 'Firefox',         'Mozilla',   NULL),
(3, 'Antivirus ESET',  'ESET',      10),
(4, 'Sage Comptabilite','Sage',     1),
(5, '7-Zip',           'Igor Pavlov', NULL),
(6, 'VLC',             'VideoLAN',  NULL);

INSERT INTO installation (id_poste, id_logiciel, version, date_install) VALUES
(1, 1, '2409', '2023-03-20'), (1, 3, '11.0', '2023-03-20'), (1, 4, 'v12', '2023-03-21'),
(2, 1, '2409', '2018-09-05'), (2, 3, '11.0', '2018-09-05'), (2, 4, 'v12', '2024-02-01'),
(3, 1, '2409', '2024-01-12'), (3, 3, '11.0', '2024-01-12'), (3, 2, '131',  '2024-01-12'),
(4, 1, '2409', '2024-06-25'), (4, 3, '11.0', '2024-06-25'),
(5, 1, '2409', '2024-06-25'), (5, 3, '11.0', '2024-06-25'), (5, 6, '3.0', '2024-07-01'),
(6, 1, '2409', '2019-02-15'), (6, 5, '23.01', '2019-02-15'),
(7, 1, '2409', '2023-03-20'), (7, 3, '11.0', '2023-03-20'), (7, 2, '131', '2023-03-20'), (7, 5, '24.08', '2023-03-20'),
(8, 1, '2409', '2025-05-10'), (8, 3, '11.0', '2025-05-10');
