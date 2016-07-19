#!/bin/bash

set -e

# Amend nGinx config
sed -i "s|_WP_HOME_|$WP_HOME|g" /etc/nginx/nginx.conf
sed -i "s|_ENV_|development|g" /etc/nginx/nginx.conf

nginx -t

# Amend php config
sed -i "s|listen = /run/php/php7.0-fpm.sock|listen = 9000|g" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s|;listen.allowed_clients|listen.allowed_clients|g" /etc/php/7.0/fpm/pool.d/www.conf

# Amend Wordpress init script
sed -i "s|_WP_HOME_|$WP_HOME|g" /init-wordpress.sh
sed -i "s|_MYSQL_DATABASE_|$MYSQL_DATABASE|g" /init-wordpress.sh
sed -i "s|_MYSQL_USER_|$MYSQL_USER|g" /init-wordpress.sh
sed -i "s|_MYSQL_PASSWORD_|$MYSQL_PASSWORD|g" /init-wordpress.sh

cd /var/www/

if ! [ -e .env.local.php -a -e composer.json ]; then
    echo >&2 "Themosis is not installed. Downloading..."

    if [ -e .gitkeep]; then
      rm .gitkeep
    fi

    git init .
    git remote add -t \* -f origin https://github.com/themosis/themosis.git
    git checkout master

    echo >&2 "Installing Themosis..."
    composer up --no-dev --no-plugins --no-scripts --prefer-dist --no-interaction --optimize-autoloader

    chown -R www-data:www-data /var/www/htdocs
    cp .env.local.php .env.development.php

    sed -i "s|database-name|$MYSQL_DATABASE|g" .env.development.php
    sed -i "s|database-user|$MYSQL_USER|g" .env.development.php
    sed -i "s|database-password|$MYSQL_PASSWORD|g" .env.development.php
    sed -i "s|localhost|$WP_HOME|g" .env.development.php
    sed -i "s|http://domain.tld|https://$WP_HOME|g" .env.development.php

    mv /environment.php /var/www/config/environment.php
    cp /var/www/config/environments/local.php /var/www/config/environments/development.php

    echo >&2 "Done! Themosis has been installed"
fi

cd /

waitforit $WP_HOME:3306 -t 5 -- ./init-wordpress.sh

exec "$@"