-- Jeu de données fictif : deux semaines de tickets dans une petite PME

PRAGMA foreign_keys = ON;

INSERT INTO technicien (id_technicien, nom, prenom, niveau) VALUES
(1, 'Martin',  'Lucas',  'N1'),
(2, 'Benali',  'Sarah',  'N1'),
(3, 'Rousseau','Thomas', 'N2'),
(4, 'Nguyen',  'Claire', 'N2');

INSERT INTO demandeur (id_demandeur, nom, prenom, service, poste_tel) VALUES
(1, 'Durand',  'Julie',   'Comptabilité', '201'),
(2, 'Petit',   'Marc',    'Comptabilité', '202'),
(3, 'Garcia',  'Ines',    'RH',           '210'),
(4, 'Moreau',  'Paul',    'Commercial',   '220'),
(5, 'Lefebvre','Emma',    'Commercial',   '221'),
(6, 'Roux',    'Hugo',    'Direction',    '100'),
(7, 'Fournier','Lea',     'Accueil',      '001'),
(8, 'Girard',  'Nathan',  'Logistique',   '230');

INSERT INTO categorie (id_categorie, nom) VALUES
(1, 'Compte / mot de passe'),
(2, 'Messagerie'),
(3, 'Impression'),
(4, 'Réseau'),
(5, 'Matériel'),
(6, 'Logiciel');

INSERT INTO sla (priorite, delai_heures) VALUES
('critique', 4),
('haute',    8),
('normale',  24),
('basse',    72);

INSERT INTO ticket (id_ticket, titre, id_demandeur, id_categorie, priorite, statut, id_technicien, escalade_n2, date_ouverture, date_resolution) VALUES
(1,  'Compte verrouillé après plusieurs essais',      1, 1, 'haute',    'clos',      1, 0, '2026-10-05 08:40', '2026-10-05 09:05'),
(2,  'Imprimante du 2e étage hors ligne',             2, 3, 'normale',  'clos',      2, 1, '2026-10-05 10:15', '2026-10-06 16:30'),
(3,  'Plus de réseau sur le poste',                   4, 4, 'haute',    'clos',      1, 0, '2026-10-05 14:00', '2026-10-05 14:45'),
(4,  'Outlook demande le mot de passe en boucle',     3, 2, 'normale',  'clos',      2, 0, '2026-10-06 09:20', '2026-10-06 11:00'),
(5,  'Serveur de fichiers inaccessible',              6, 4, 'critique', 'clos',      3, 1, '2026-10-06 08:05', '2026-10-06 13:40'),
(6,  'Installer le logiciel de paie sur un poste',    3, 6, 'basse',    'clos',      1, 0, '2026-10-06 15:00', '2026-10-08 10:00'),
(7,  'Écran qui clignote',                            7, 5, 'normale',  'resolu',    2, 0, '2026-10-07 09:00', '2026-10-07 10:30'),
(8,  'Mot de passe expiré, impossible de se connecter',8, 1, 'haute',   'resolu',    1, 0, '2026-10-07 13:10', '2026-10-07 13:25'),
(9,  'Wifi salle de réunion très lent',               5, 4, 'normale',  'resolu',    4, 1, '2026-10-08 10:00', '2026-10-09 15:00'),
(10, 'Bourrage papier à répétition',                  1, 3, 'basse',    'resolu',    2, 0, '2026-10-09 11:30', '2026-10-09 16:00'),
(11, 'Boîte mail pleine',                             4, 2, 'normale',  'resolu',    1, 0, '2026-10-12 08:50', '2026-10-12 09:30'),
(12, 'Clavier qui ne répond plus',                    2, 5, 'basse',    'resolu',    2, 0, '2026-10-12 14:00', '2026-10-13 09:00'),
(13, 'VPN impossible depuis le domicile',             6, 4, 'haute',    'resolu',    3, 1, '2026-10-13 07:45', '2026-10-13 18:10'),
(14, 'Compte verrouillé',                             1, 1, 'haute',    'resolu',    1, 0, '2026-10-14 08:35', '2026-10-14 08:50'),
(15, 'Excel plante à l''ouverture d''un fichier',     5, 6, 'normale',  'en cours',  2, 0, '2026-10-15 10:00', NULL),
(16, 'Scanner réseau ne trouve plus le dossier',      7, 3, 'normale',  'en attente',4, 1, '2026-10-15 11:20', NULL),
(17, 'Nouvel arrivant : création de compte',          3, 1, 'normale',  'nouveau',   NULL, 0, '2026-10-16 09:00', NULL),
(18, 'PC très lent au démarrage',                     8, 5, 'basse',    'nouveau',   NULL, 0, '2026-10-16 14:30', NULL),
(19, 'Partage réseau Compta inaccessible',            2, 4, 'critique', 'en cours',  3, 1, '2026-10-16 15:10', NULL);
