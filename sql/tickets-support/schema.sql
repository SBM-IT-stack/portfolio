-- Base de suivi des tickets de support (SQLite)
-- Ordre de création : d'abord les tables qui ne dépendent de rien.

PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS v_tickets_ouverts;
DROP VIEW IF EXISTS v_delais;
DROP TABLE IF EXISTS historique_statut;
DROP TABLE IF EXISTS ticket;
DROP TABLE IF EXISTS sla;
DROP TABLE IF EXISTS categorie;
DROP TABLE IF EXISTS demandeur;
DROP TABLE IF EXISTS technicien;

CREATE TABLE technicien (
    id_technicien  INTEGER PRIMARY KEY,
    nom            TEXT NOT NULL,
    prenom         TEXT NOT NULL,
    niveau         TEXT NOT NULL CHECK (niveau IN ('N1', 'N2'))
);

CREATE TABLE demandeur (
    id_demandeur   INTEGER PRIMARY KEY,
    nom            TEXT NOT NULL,
    prenom         TEXT NOT NULL,
    service        TEXT NOT NULL,
    poste_tel      TEXT
);

CREATE TABLE categorie (
    id_categorie   INTEGER PRIMARY KEY,
    nom            TEXT NOT NULL UNIQUE
);

-- Délai maximum de résolution selon la priorité (en heures)
CREATE TABLE sla (
    priorite       TEXT PRIMARY KEY CHECK (priorite IN ('basse', 'normale', 'haute', 'critique')),
    delai_heures   INTEGER NOT NULL
);

-- Les dates sont au format 'AAAA-MM-JJ HH:MM'
CREATE TABLE ticket (
    id_ticket        INTEGER PRIMARY KEY,
    titre            TEXT NOT NULL,
    id_demandeur     INTEGER NOT NULL,
    id_categorie     INTEGER NOT NULL,
    priorite         TEXT NOT NULL DEFAULT 'normale',
    statut           TEXT NOT NULL DEFAULT 'nouveau'
                     CHECK (statut IN ('nouveau', 'en cours', 'en attente', 'resolu', 'clos')),
    id_technicien    INTEGER,          -- NULL tant que personne ne l'a pris
    escalade_n2      INTEGER NOT NULL DEFAULT 0 CHECK (escalade_n2 IN (0, 1)),
    date_ouverture   TEXT NOT NULL,
    date_resolution  TEXT,             -- remplie quand le ticket passe en 'resolu'
    FOREIGN KEY (id_demandeur) REFERENCES demandeur(id_demandeur),
    FOREIGN KEY (id_categorie) REFERENCES categorie(id_categorie),
    FOREIGN KEY (id_technicien) REFERENCES technicien(id_technicien),
    FOREIGN KEY (priorite) REFERENCES sla(priorite)
);

-- Chaque changement de statut est enregistré ici par le trigger
CREATE TABLE historique_statut (
    id_historique    INTEGER PRIMARY KEY,
    id_ticket        INTEGER NOT NULL,
    ancien_statut    TEXT,
    nouveau_statut   TEXT NOT NULL,
    date_changement  TEXT NOT NULL,
    FOREIGN KEY (id_ticket) REFERENCES ticket(id_ticket)
);

-- Index sur les colonnes qu'on filtre le plus souvent
CREATE INDEX idx_ticket_statut ON ticket(statut);
CREATE INDEX idx_ticket_technicien ON ticket(id_technicien);

-- Trigger : quand le statut change, on garde une trace,
-- et si le ticket passe en 'resolu' on note la date de résolution.
CREATE TRIGGER trg_changement_statut
AFTER UPDATE OF statut ON ticket
WHEN OLD.statut <> NEW.statut
BEGIN
    INSERT INTO historique_statut (id_ticket, ancien_statut, nouveau_statut, date_changement)
    VALUES (NEW.id_ticket, OLD.statut, NEW.statut, strftime('%Y-%m-%d %H:%M', 'now', 'localtime'));

    UPDATE ticket
    SET date_resolution = strftime('%Y-%m-%d %H:%M', 'now', 'localtime')
    WHERE id_ticket = NEW.id_ticket
      AND NEW.statut = 'resolu'
      AND date_resolution IS NULL;
END;

-- Vue : tickets pas encore résolus, avec les infos utiles d'un coup d'oeil
CREATE VIEW v_tickets_ouverts AS
SELECT t.id_ticket, t.titre, t.priorite, t.statut,
       d.prenom || ' ' || d.nom AS demandeur, d.service,
       c.nom AS categorie,
       COALESCE(te.prenom || ' ' || te.nom, '(non assigné)') AS technicien,
       t.date_ouverture
FROM ticket t
JOIN demandeur d ON d.id_demandeur = t.id_demandeur
JOIN categorie c ON c.id_categorie = t.id_categorie
LEFT JOIN technicien te ON te.id_technicien = t.id_technicien
WHERE t.statut NOT IN ('resolu', 'clos');

-- Vue : délai de résolution en heures et respect du SLA (tickets résolus ou clos)
CREATE VIEW v_delais AS
SELECT t.id_ticket, t.titre, t.priorite, c.nom AS categorie, t.id_technicien,
       ROUND((julianday(t.date_resolution) - julianday(t.date_ouverture)) * 24, 1) AS heures,
       s.delai_heures,
       CASE WHEN (julianday(t.date_resolution) - julianday(t.date_ouverture)) * 24 <= s.delai_heures
            THEN 'ok' ELSE 'hors delai' END AS respect_sla
FROM ticket t
JOIN categorie c ON c.id_categorie = t.id_categorie
JOIN sla s ON s.priorite = t.priorite
WHERE t.date_resolution IS NOT NULL;
