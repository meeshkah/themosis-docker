#!/bin/bash

set -e

# Amend nGinx config
sed -i "s|_WP_HOME_|$WP_HOME|g" /etc/nginx/nginx.conf

# Amend Wordpress init script
sed -i "s|_WP_HOME_|$WP_HOME|g" /init-wordpress.sh
sed -i "s|_MYSQL_DATABASE_|$MYSQL_DATABASE|g" /init-wordpress.sh
sed -i "s|_MYSQL_USER_|$MYSQL_USER|g" /init-wordpress.sh
sed -i "s|_MYSQL_PASSWORD_|$MYSQL_PASSWORD|g" /init-wordpress.sh

cd /var/www/

if ! [ -e .env.local.php -a -e composer.json ]; then
    echo >&2 "Themosis is not installed. Downloading..."

    rm .gitkeep
    git clone https://github.com/themosis/themosis.git .

    echo >&2 "Installing Themosis..."
    composer up --no-dev --prefer-dist --no-interaction --optimize-autoloader

    chown -R www-data:www-data /var/www/htdocs
    cp .env.local.php .env.development.php

    sed -i "s|database_name|$MYSQL_DATABASE|g" .env.development.php
    sed -i "s|database_user|$MYSQL_USER|g" .env.development.php
    sed -i "s|database_password|$MYSQL_PASSWORD|g" .env.development.php
    sed -i "s|http://domain.tld|https://$WP_HOME|g" .env.development.php

    echo >&2 "Done! Themosis has been installed"
fi

waitforit localhost:3306 -t 5 -- ./init-wordpress.sh