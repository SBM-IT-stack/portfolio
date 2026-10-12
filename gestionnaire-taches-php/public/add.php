<?php
require __DIR__ . '/db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: index.php');
    exit;
}

$title = trim($_POST['title'] ?? '');
$description = trim($_POST['description'] ?? '');

if ($title === '') {
    header('Location: index.php');
    exit;
}

$stmt = $pdo->prepare('INSERT INTO tasks (title, description, status) VALUES (:title, :description, :status)');
$stmt->execute([
    ':title' => $title,
    ':description' => $description,
    ':status' => 'a_faire',
]);

header('Location: index.php');
exit;
