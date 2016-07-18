#!/bin/bash
USER_PASS=`openssl rand -base64 8`

cd /var/www/htdocs/cms
if ! $(wp core is-installed --allow-root); then
  echo >&2 "Switching Wordpress on..."
  wp core config --dbname=${MYSQL_DATABASE} \
                 --dbuser=${MYSQL_USER} \
                 --dbpass=${MYSQL_PASSWORD} \
                 --allow-root
  wp core install --url=http://${WP_HOME}/cms/ \
                  --title=Themosis \
                  --admin_user=admin \
                  --admin_password=$USER_PASS \
                  --admin_email=admin@example.com \
                  --allow-root
  echo >&2 "Done!"
  echo >&2 "========================="
  echo >&2 "User: admin"
  echo >&2 "Pass: $USER_PASS"
  echo >&2 "========================="
else
  echo >&2 "Wordpress installed. Carrying on..."
fi
cd /