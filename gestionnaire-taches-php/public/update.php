<?php
require __DIR__ . '/db.php';

$allowedStatuses = ['a_faire', 'en_cours', 'termine'];

$id = (int)($_POST['id'] ?? 0);
$status = $_POST['status'] ?? '';

if ($id > 0 && in_array($status, $allowedStatuses, true)) {
    $stmt = $pdo->prepare('UPDATE tasks SET status = :status WHERE id = :id');
    $stmt->execute([':status' => $status, ':id' => $id]);
}

header('Location: index.php');
exit;
