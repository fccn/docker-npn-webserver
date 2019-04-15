#-----------------------------------------------------------------------
# Docker Image for Nginx-PHP7-NodeJS Web application
#   - nginx configured for https with self-signed certificate
#   - all services are run by application user
# Uses multi-stage building allowing a single Dockerfile for all environments
#-----------------------------------------------------------------------
FROM php:7-fpm-alpine as base
# prepare PHP NodeJS environment
LABEL maintainer="Paulo Costa <paulo.costa@fccn.pt>"

#---- prepare environment variables
ARG NPM_VERSION=6
ARG APP_ROOT=/app
ARG WEB_DOCUMENT_ROOT=/app/html
ARG PHP_ROOT=/usr/local/etc/php
ARG PHP_FPM_ROOT=/usr/local/etc
ARG NGINX_ROOT=/etc/nginx

#------ timezone and users
ENV TZ=Europe/Lisbon

#add required packages
RUN echo '@testing http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
  && echo '@community http://nl.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
  && echo '@edge http://nl.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories \
  && apk update && apk upgrade --no-cache --available && apk add --upgrade apk-tools@edge \
#------ set timezone
  && apk --no-cache add ca-certificates && update-ca-certificates \
  && apk add --update tzdata && cp /usr/share/zoneinfo/Europe/Lisbon /etc/localtime \
#additional packages
  && apk add --no-cache --update curl tar bzip2 openssh git gettext-dev icu-dev gmp-dev \
	nodejs@edge yarn@edge nodejs-npm make nginx freetype libpng libjpeg-turbo \
  && rm -rf /var/cache/apk/* \
#prepare .ssh folder and add github and fccn's gitlab ssh keys
  && mkdir -p ~/.ssh && chmod 700 ~/.ssh \
  ; ssh-keyscan gitlab.fccn.pt >> ~/.ssh/known_hosts \
  ; ssh-keyscan github.com >> ~/.ssh/known_hosts \
#add application user and group
  && addgroup -g 1000 application && adduser -u 1000 -G application -D application \
  && chown -R application:application /home/application

#--- PHP

#-install php libs
#  intl, gettext - required for translation mechanisms
#  pcntl -
#  gmp - required for php-openid
RUN apk update && apk add --no-cache --update --virtual buildDeps \
 freetype-dev libpng-dev libjpeg-turbo-dev mariadb-dev \
 && docker-php-ext-install pdo_mysql \
 && docker-php-ext-install intl \
 && docker-php-ext-install gettext \
 && docker-php-ext-install pcntl \
 && docker-php-ext-install gmp \
#-install gd
 && docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
 && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && docker-php-ext-install -j${NPROC} gd \
#-remove unecessary libs
 && apk del buildDeps \
 && rm -rf /var/cache/apk/*

#create self-signed certificate for ssl access
WORKDIR ${NGINX_ROOT}/ssl
RUN openssl req -x509 -nodes -newkey rsa:4096 -keyout docker_selfsigned.key -out docker_selfsigned.crt \
  -subj "/C=PT/ST=Lisbon/L=Lisbon/O=FCT|FCCN/OU=STV/CN=docker" -days 3650

#-prepare startup
COPY build/entrypoint.sh /tmp/entrypoint.sh

RUN chmod 755 /tmp/entrypoint.sh \
  && mkdir -p /run/nginx && mkdir -p ${APP_ROOT} \
#- change owner of /var/tmp/nginx to prevent cutting long outputs (https://github.com/phpearth/docker-php/issues/9)
  && chown -R application:application /var/tmp/nginx \
#change ownership of application root folder
  && chown -R application:application ${APP_ROOT}


FROM scratch as devel-env
LABEL maintainer="Paulo Costa <paulo.costa@fccn.pt>"
#--- copy contents from base image
COPY --from=base / /

#--- PHP configurations
COPY config/php/conf.d/xzz_fccn-commons.ini ${PHP_ROOT}/conf.d/xzz_fccn-commons.ini
COPY config/php/php-fpm.d/www.conf ${PHP_FPM_ROOT}/php-fpm.d/www.conf
COPY config/php/php-fpm.d/zz-docker.conf ${PHP_FPM_ROOT}/php-fpm.d/zz-docker.conf

#--- NGINX configurations
COPY config/nginx/conf.d ${NGINX_ROOT}/conf.d
COPY config/nginx/90-webapp-settings.conf ${NGINX_ROOT}/90-webapp-settings.conf
COPY config/nginx/nginx.conf ${NGINX_ROOT}/nginx.conf
COPY config/nginx/mime.types ${NGINX_ROOT}/mime.types
COPY config/nginx/ssl.conf ${NGINX_ROOT}/ssl.conf

#---- Install additional Tools
WORKDIR /tmp
#-install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php \
  && php -r "unlink('composer-setup.php');" && cp composer.phar /usr/local/bin/composer \
#-install codeception
  && curl -LsS https://codeception.com/codecept.phar -o /usr/local/bin/codecept \
  &&  chmod a+x /usr/local/bin/codecept \
#-install grunt
  && npm install -g grunt \
#-make sure home for application user has right permissions
  && chown -R application:application /home/application

FROM scratch
# production image
LABEL maintainer="Paulo Costa <paulo.costa@fccn.pt>"
#--- copy contents from base image
COPY --from=base / /

#---- prepare environment variables
ARG APP_ROOT=/app
ARG WEB_DOCUMENT_ROOT=/app/html
ARG PHP_ROOT=/usr/local/etc/php
ARG PHP_FPM_ROOT=/usr/local/etc
ARG NGINX_ROOT=/etc/nginx

#--- PHP configurations
COPY config/php/conf.d/xzz_fccn-commons.ini ${PHP_ROOT}/conf.d/xzz_fccn-commons.ini
COPY config/php/php-fpm.d/www.conf ${PHP_FPM_ROOT}/php-fpm.d/www.conf
COPY config/php/php-fpm.d/zz-docker.conf ${PHP_FPM_ROOT}/php-fpm.d/zz-docker.conf

#--- NGINX configurations
COPY config/nginx/conf.d ${NGINX_ROOT}/conf.d
COPY config/nginx/90-webapp-settings.conf ${NGINX_ROOT}/90-webapp-settings.conf
COPY config/nginx/nginx.conf ${NGINX_ROOT}/nginx.conf
COPY config/nginx/mime.types ${NGINX_ROOT}/mime.types
COPY config/nginx/ssl.conf ${NGINX_ROOT}/ssl.conf

WORKDIR ${APP_ROOT}

#make sure home for application user has right permissions
RUN chown -R application:application /home/application
  # display version numbers
  echo "Using libraries:"; echo " - NPM " $(npm -v); echo " - NodeJS " $(node -v); echo $(php -v); \
	echo $(nginx -v);
CMD ["/tmp/entrypoint.sh"]
