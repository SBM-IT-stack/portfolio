<?php
/**
 * db.php : connexion à la base de données (PDO).
 *
 * Par défaut : SQLite (zéro configuration, un simple fichier tasks.db).
 * Pour passer à MySQL, remplace le bloc "SQLite" ci-dessous par le bloc
 * "MySQL" en commentaire, et utilise sql/schema_mysql.sql pour créer la table.
 */

// --- SQLite (par défaut, aucune installation de serveur nécessaire) ---
$dbFile = __DIR__ . '/../tasks.db';
$isNewDb = !file_exists($dbFile);

try {
    $pdo = new PDO('sqlite:' . $dbFile);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    die('Erreur de connexion à la base de données : ' . htmlspecialchars($e->getMessage()));
}

// Création automatique de la table au premier lancement
if ($isNewDb) {
    $pdo->exec("
        CREATE TABLE tasks (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            title       TEXT NOT NULL,
            description TEXT DEFAULT '',
            status      TEXT NOT NULL DEFAULT 'a_faire',
            created_at  TEXT NOT NULL DEFAULT (datetime('now'))
        )
    ");
}

/*
// --- MySQL (alternative) ---
$host = 'localhost';
$dbname = 'gestionnaire_taches';
$user = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    http_response_code(500);
    die('Erreur de connexion à la base de données : ' . htmlspecialchars($e->getMessage()));
}
*/
