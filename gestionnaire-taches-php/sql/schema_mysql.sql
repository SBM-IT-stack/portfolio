-- Schéma pour MySQL / MariaDB
-- (à utiliser seulement si tu passes de SQLite à MySQL dans public/db.php)

CREATE DATABASE IF NOT EXISTS gestionnaire_taches CHARACTER SET utf8mb4;
USE gestionnaire_taches;

CREATE TABLE IF NOT EXISTS tasks (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(120) NOT NULL,
    description TEXT,
    status      ENUM('a_faire', 'en_cours', 'termine') NOT NULL DEFAULT 'a_faire',
    created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
