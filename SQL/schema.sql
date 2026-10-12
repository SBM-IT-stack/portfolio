-- Base d'inventaire de parc informatique (SQLite)
-- Ordre de création : d'abord les tables qui ne dépendent de rien.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS installation;
DROP TABLE IF EXISTS logiciel;
DROP TABLE IF EXISTS poste;
DROP TABLE IF EXISTS utilisateur;
DROP TABLE IF EXISTS service;

CREATE TABLE service (
    id_service  INTEGER PRIMARY KEY,
    nom         TEXT NOT NULL UNIQUE,
    etage       INTEGER
);

CREATE TABLE utilisateur (
    id_utilisateur  INTEGER PRIMARY KEY,
    nom             TEXT NOT NULL,
    prenom          TEXT NOT NULL,
    login           TEXT NOT NULL UNIQUE,
    id_service      INTEGER NOT NULL,
    FOREIGN KEY (id_service) REFERENCES service(id_service)
);

-- Un poste peut ne pas avoir d'utilisateur (en stock ou en panne)
CREATE TABLE poste (
    id_poste         INTEGER PRIMARY KEY,
    nom_machine      TEXT NOT NULL UNIQUE,
    type             TEXT NOT NULL CHECK (type IN ('fixe', 'portable')),
    marque           TEXT,
    modele           TEXT,
    num_serie        TEXT UNIQUE,
    os               TEXT,
    ram_go           INTEGER,
    adresse_ip       TEXT,
    date_achat       TEXT,   -- format AAAA-MM-JJ
    fin_garantie     TEXT,   -- format AAAA-MM-JJ
    etat             TEXT NOT NULL DEFAULT 'en service'
                     CHECK (etat IN ('en service', 'stock', 'panne', 'reforme')),
    id_utilisateur   INTEGER,
    FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur)
);

CREATE TABLE logiciel (
    id_logiciel      INTEGER PRIMARY KEY,
    nom              TEXT NOT NULL,
    editeur          TEXT,
    nb_licences      INTEGER    -- NULL si logiciel libre ou sans limite
);

-- Table de liaison : quels logiciels sont installés sur quel poste
CREATE TABLE installation (
    id_poste         INTEGER NOT NULL,
    id_logiciel      INTEGER NOT NULL,
    version          TEXT,
    date_install     TEXT,
    PRIMARY KEY (id_poste, id_logiciel),
    FOREIGN KEY (id_poste) REFERENCES poste(id_poste),
    FOREIGN KEY (id_logiciel) REFERENCES logiciel(id_logiciel)
);
