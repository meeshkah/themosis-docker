FROM phusion/baseimage:0.9.19

MAINTAINER Misha Rumbesht <m.rumbesht@gmail.com>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update

# Add nGinx repo
RUN add-apt-repository -y ppa:nginx/stable

RUN \
  apt-get install -y software-properties-common && \
  apt-get update && apt-get upgrade -y

# Basic Requirements
RUN apt-get install -y git unzip wget python-pip gettext

# Install nGinx
RUN \
  apt-get install -y nginx && \
  rm -rf /var/lib/apt/lists/* && \
  chown -R www-data:www-data /var/lib/nginx

# Remove default settings
RUN rm /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default

# Create config from tempalte
COPY .docker/dev/nginx/themosis.nginx.conf.template /tmp/nginx.conf.template
RUN envsubst '$WP_ENV $WP_HOME' < /tmp/nginx.conf.template > /etc/nginx/nginx.conf

# Define mountable directories.
VOLUME ["/etc/nginx/certs", "/var/www"]

# Expose ports.
EXPOSE 80
EXPOSE 443

# Add php 7 ppa
RUN LC_ALL=en_US.UTF-8 add-apt-repository -y ppa:ondrej/php && apt-get update

# Install php
RUN apt-get install -y php7.0-cli php7.0-common php7.0 php7.0-mysql php7.0-fpm php7.0-curl php7.0-gd php7.0-mysql php7.0-bz2

WORKDIR /

# Install wait-for-it
RUN curl -O https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh
RUN chmod +x wait-for-it.sh
RUN mv wait-for-it.sh /usr/local/bin/waitforit

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN chmod +x composer.phar
RUN mv composer.phar /usr/local/bin/composer

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

# Install ngxtop, useful for debugging
RUN pip install ngxtop

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
RUN sed -i "/# server_name_in_redirect off;/ a\fastcgi_cache_path /var/run/nginx levels=1:2 keys_zone=drm_custom_cache:16m max_size=1024m inactive=60m;" /etc/nginx/nginx.conf

COPY .docker/dev/themosis/entry-point.sh /tmp/entry-point.sh
RUN envsubst < /tmp/entry-point.sh > /entry-point.sh
RUN chmod +x entry-point.sh
COPY .docker/dev/db/init-wordpress.sh /tmp/init-wordpress.sh
RUN envsubst < /tmp/init-wordpress.sh > /init-wordpress.sh
RUN chmod +x init-wordpress.sh

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*