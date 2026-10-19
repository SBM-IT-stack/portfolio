#!/bin/bash
# Installation de GLPI 11 sur une Debian 13 fraîche (Apache, PHP-FPM, MariaDB).
# A lancer en root sur la VM du lab : sudo ./install-glpi.sh
# L'installation se termine ensuite dans le navigateur.

set -e

# Variables à adapter
GLPI_VERSION="11.0.4"
PHP_VERSION="8.4"
NOM_SITE="glpi.lab.local"
DB_NOM="glpi"
DB_USER="glpi_user"
# Mot de passe généré au hasard, affiché à la fin
DB_PASS="$(openssl rand -base64 18)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être lancé en root (sudo)."
    exit 1
fi

if [ -d /var/www/glpi ]; then
    echo "/var/www/glpi existe déjà, j'arrête pour ne rien écraser."
    exit 1
fi

echo "[1/6] Paquets"
apt-get update
apt-get install -y apache2 mariadb-server wget openssl \
    "php${PHP_VERSION}-fpm" "php${PHP_VERSION}-curl" "php${PHP_VERSION}-gd" \
    "php${PHP_VERSION}-intl" "php${PHP_VERSION}-mysql" "php${PHP_VERSION}-zip" \
    "php${PHP_VERSION}-bcmath" "php${PHP_VERSION}-mbstring" "php${PHP_VERSION}-xml" \
    "php${PHP_VERSION}-bz2" "php${PHP_VERSION}-ldap"

echo "[2/6] Base de données"
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NOM} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NOM}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[3/6] Téléchargement de GLPI ${GLPI_VERSION}"
cd /tmp
wget -q "https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz"
tar -xzf "glpi-${GLPI_VERSION}.tgz" -C /var/www/

echo "[4/6] Dossiers config, files et log sortis du dossier web"
mkdir -p /etc/glpi /var/lib/glpi /var/log/glpi
cp -a /var/www/glpi/config/. /etc/glpi/
mv /var/www/glpi/files /var/lib/glpi/

cat > /var/www/glpi/inc/downstream.php <<'EOF'
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF

cat > /etc/glpi/local_define.php <<'EOF'
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi/files');
define('GLPI_LOG_DIR', '/var/log/glpi');
EOF

# www-data doit pouvoir écrire dans ces dossiers
chown -R www-data:www-data /var/www/glpi /etc/glpi /var/lib/glpi /var/log/glpi

echo "[5/6] Apache"
cat > "/etc/apache2/sites-available/${NOM_SITE}.conf" <<EOF
<VirtualHost *:80>
    ServerName ${NOM_SITE}
    DocumentRoot /var/www/glpi/public

    <Directory /var/www/glpi/public>
        Require all granted
        RewriteEngine On
        # Nécessaire pour l'API
        RewriteCond %{HTTP:Authorization} ^(.+)\$
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
        # Tout ce qui n'est pas un fichier passe par le routeur de GLPI
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)\$ index.php [QSA,L]
    </Directory>

    <FilesMatch \.php\$>
        SetHandler "proxy:unix:/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost/"
    </FilesMatch>
</VirtualHost>
EOF

a2ensite "${NOM_SITE}.conf"
a2dissite 000-default.conf
a2enmod rewrite proxy_fcgi setenvif
a2enconf "php${PHP_VERSION}-fpm"

echo "[6/6] PHP (cookies de session)"
PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
sed -i 's/^;\?session.cookie_httponly.*/session.cookie_httponly = On/' "$PHP_INI"
sed -i 's/^;\?session.cookie_samesite.*/session.cookie_samesite = Lax/' "$PHP_INI"

systemctl restart "php${PHP_VERSION}-fpm"
systemctl reload apache2

echo
echo "Terminé. Ouvre http://${NOM_SITE} pour finir l'installation."
echo "Base : ${DB_NOM}  Utilisateur : ${DB_USER}  Mot de passe : ${DB_PASS}"
echo "Note ce mot de passe, il n'est enregistré nulle part."
echo "Après l'assistant : change les mots de passe des comptes par défaut"
echo "et supprime /var/www/glpi/install/install.php"
