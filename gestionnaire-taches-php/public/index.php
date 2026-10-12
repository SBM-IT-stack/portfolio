<?php
require __DIR__ . '/db.php';

$statusLabels = [
    'a_faire'   => 'À faire',
    'en_cours'  => 'En cours',
    'termine'   => 'Terminé',
];

$tasks = $pdo->query('SELECT * FROM tasks ORDER BY
        CASE status WHEN "a_faire" THEN 0 WHEN "en_cours" THEN 1 ELSE 2 END,
        created_at DESC')->fetchAll();
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestionnaire de tâches</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="wrap">
        <header class="app-header">
            <p class="eyebrow">$ gestionnaire-taches --demo</p>
            <h1>Tâches</h1>
            <p class="subtitle"><?= count($tasks) ?> tâche(s) au total</p>
        </header>

        <section class="card add-task-card">
            <h2>Nouvelle tâche</h2>
            <form action="add.php" method="post" class="task-form">
                <input type="text" name="title" placeholder="Titre de la tâche" required maxlength="120">
                <textarea name="description" placeholder="Description (optionnel)" rows="2"></textarea>
                <button type="submit" class="btn btn-primary">Ajouter</button>
            </form>
        </section>

        <section class="task-list">
            <?php if (empty($tasks)): ?>
                <p class="empty-state">Aucune tâche pour l'instant, ajoute la première ci-dessus.</p>
            <?php else: ?>
                <?php foreach ($tasks as $task): ?>
                    <article class="card task-item status-<?= htmlspecialchars($task['status']) ?>">
                        <div class="task-main">
                            <span class="status-dot"></span>
                            <div>
                                <h3><?= htmlspecialchars($task['title']) ?></h3>
                                <?php if (!empty($task['description'])): ?>
                                    <p class="task-desc"><?= htmlspecialchars($task['description']) ?></p>
                                <?php endif; ?>
                                <p class="task-meta">Créée le <?= htmlspecialchars($task['created_at']) ?></p>
                            </div>
                        </div>
                        <div class="task-actions">
                            <form action="update.php" method="post">
                                <input type="hidden" name="id" value="<?= (int)$task['id'] ?>">
                                <select name="status" onchange="this.form.submit()">
                                    <?php foreach ($statusLabels as $value => $label): ?>
                                        <option value="<?= $value ?>" <?= $task['status'] === $value ? 'selected' : '' ?>>
                                            <?= $label ?>
                                        </option>
                                    <?php endforeach; ?>
                                </select>
                            </form>
                            <form action="delete.php" method="post" onsubmit="return confirm('Supprimer cette tâche ?');">
                                <input type="hidden" name="id" value="<?= (int)$task['id'] ?>">
                                <button type="submit" class="btn btn-danger">Supprimer</button>
                            </form>
                        </div>
                    </article>
                <?php endforeach; ?>
            <?php endif; ?>
        </section>
    </div>
</body>
</html>
