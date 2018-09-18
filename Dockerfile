#-----------------------------------------------------------------------
# Docker Image for Nginx-PHP7-NodeJS Web application
#   - nginx configured for https with self-signed certificate
#   - all services are run by application user
#-----------------------------------------------------------------------
FROM php:7-fpm-alpine
MAINTAINER Paulo Costa <paulo.costa@fccn.pt>

#---- prepare environment variables
ENV APP_ROOT /app
ENV WEB_DOCUMENT_ROOT /app/html
ENV PHP_ROOT /usr/local/etc/php
ENV PHP_FPM_ROOT /usr/local/etc
ENV NGINX_ROOT /etc/nginx

ENV YARN_VERSION 1.7.0

#add testing and community repositories
RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories && \
  echo '@community http://nl.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories && \
  echo '@edge http://nl.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories && \
  apk update && apk upgrade --no-cache --available
RUN apk add --upgrade apk-tools@edge

#------ set timezone
RUN apk --no-cache add ca-certificates && update-ca-certificates
# Change TimeZone
RUN apk add --update tzdata
ENV TZ=Europe/Lisbon
RUN cp /usr/share/zoneinfo/Europe/Lisbon /etc/localtime

#add application user and group
RUN addgroup -g 1000 application && adduser -u 1000 -G application -D application

#additional packages
RUN apk add --no-cache --update curl tar bzip2 openssh git gettext-dev icu-dev gmp-dev \ 
	nodejs nodejs-npm make nginx \
	freetype libpng libjpeg-turbo

RUN apk add --no-cache --update --virtual buildDeps freetype-dev libpng-dev libjpeg-turbo-dev mariadb-dev
	
#--- PHP

#-install php libs
#  intl, gettext - required for translation mechanisms
#  pcntl - 
#  gmp - required for php-openid
RUN docker-php-ext-install pdo_mysql && \
    docker-php-ext-install intl && \
    docker-php-ext-install gettext && \
	docker-php-ext-install pcntl && \
	docker-php-ext-install gmp

#-install gd
RUN docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ && \
  NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  docker-php-ext-install -j${NPROC} gd
	
#-configure php
ADD config/php/conf.d/xzz_fccn-commons.ini $PHP_ROOT/conf.d/xzz_fccn-commons.ini
ADD config/php/php-fpm.d/www.conf $PHP_FPM_ROOT/php-fpm.d/www.conf
ADD config/php/php-fpm.d/zz-docker.conf $PHP_FPM_ROOT/php-fpm.d/zz-docker.conf

#--- NGINX
	
#-configure nginx
COPY config/nginx/conf.d $NGINX_ROOT/conf.d
COPY config/nginx/90-webapp-settings.conf $NGINX_ROOT/90-webapp-settings.conf
COPY config/nginx/nginx.conf $NGINX_ROOT/nginx.conf
COPY config/nginx/mime.types $NGINX_ROOT/mime.types
COPY config/nginx/ssl.conf $NGINX_ROOT/ssl.conf

#change owner of /var/tmp/nginx to prevent cutting long outputs (https://github.com/phpearth/docker-php/issues/9)
RUN chown -R application:application /var/tmp/nginx

#create self-signed certificate for ssl access
WORKDIR $NGINX_ROOT/ssl
RUN openssl req -x509 -nodes -newkey rsa:4096 -keyout docker_selfsigned.key -out docker_selfsigned.crt \
  -subj "/C=PT/ST=Lisbon/L=Lisbon/O=FCT|FCCN/OU=STV/CN=docker" -days 3650

#---- Tools

#workaround for manual update of npm
WORKDIR /tmp/npm-install-directory
RUN npm install npm@6 && \
    rm -rf /usr/lib/node_modules  && \
    mv node_modules /usr/lib/

WORKDIR /tmp
#-install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  php composer-setup.php && \
  php -r "unlink('composer-setup.php');" && cp composer.phar /usr/local/bin/composer

#-install codeception
RUN curl -LsS https://codeception.com/codecept.phar -o /usr/local/bin/codecept && \
  chmod a+x /usr/local/bin/codecept
  
#-install grunt
RUN npm install -g grunt

#-prepare startup
ADD build/entrypoint.sh /tmp/entrypoint.sh
RUN chmod 755 /tmp/entrypoint.sh

WORKDIR $APP_ROOT
#change ownership of application
RUN chown -R application:application $APP_ROOT

#-remove unecessary libs
RUN apk del buildDeps

RUN mkdir -p /run/nginx

# display version numbers
RUN echo "Using libraries:"; echo " - NPM " $(npm -v); echo " - NodeJS " $(node -v); echo $(php -v); \
	echo $(nginx -v);
CMD ["/tmp/entrypoint.sh"]
