FROM phusion/baseimage:0.9.19

MAINTAINER Misha Rumbesht <m.rumbesht@gmail.com>

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Add nGinx repo
RUN add-apt-repository -y ppa:nginx/stable

RUN \
  apt-get update && \
  apt-get -y upgrade \
  apt-get install -y software-properties-common

# Basic Requirements
RUN apt-get install -y curl php-cli php-mbstring git unzip wget python-pip

# Install nGinx
RUN \
  apt-get install -y nginx && \
  rm -rf /var/lib/apt/lists/* && \
  echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
  chown -R www-data:www-data /var/lib/nginx

RUN rm /etc/nginx/sites-enabled/default

# Define mountable directories.
# VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]

# Expose ports.
EXPOSE 80
EXPOSE 443

# Install php
RUN apt-get install -y php-curl php-gd php-mcrypt php-xml php-xmlrpc

WORKDIR /

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN chmod +x composer.phar
RUN mv composer.phar /usr/local/bin/composer

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log
RUN sed -i "/# server_name_in_redirect off;/ a\fastcgi_cache_path /var/run/nginx levels=1:2 keys_zone=drm_custom_cache:16m max_size=1024m inactive=60m;" /etc/nginx/nginx.conf

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*