#!/usr/bin/env sh

export NGINX_CONF=${NGINX_CONF:-'/etc/nginx/nginx.conf'}
export PHP_FPM_CONF=${PHP_FPM_CONF:-'/usr/local/etc/php-fpm.conf'}
export APP_LOCALE_PATH=/app/locale

TRAPPED_SIGNAL=false

echo 'Preparing language files';
cd $APP_LOCALE_PATH && make clean && make
chown -R application:application $APP_LOCALE_PATH

echo 'Starting NGINX';
nginx -c $NGINX_CONF  -g 'daemon off;' 2>&1 &
NGINX_PID=$!

echo 'Starting PHP-FPM';
php-fpm -R -F -c $PHP_FPM_CONF 2>&1 &
PHP_FPM_PID=$!

trap "TRAPPED_SIGNAL=true; kill -15 $NGINX_PID; kill -15 $PHP_FPM_PID;" SIGTERM  SIGINT

while :
do
    kill -0 $NGINX_PID 2> /dev/null
    NGINX_STATUS=$?

    kill -0 $PHP_FPM_PID 2> /dev/null
    PHP_FPM_STATUS=$?

    if [ "$TRAPPED_SIGNAL" = "false" ]; then
        if [ $NGINX_STATUS -ne 0 ] || [ $PHP_FPM_STATUS -ne 0 ]; then
            if [ $NGINX_STATUS -eq 0 ]; then
                kill -15 $NGINX_PID;
                wait $NGINX_PID;
            fi
            if [ $PHP_FPM_STATUS -eq 0 ]; then
                kill -15 $PHP_FPM_PID;
                wait $PHP_FPM_PID;
            fi

            exit 1;
        fi
    else
       if [ $NGINX_STATUS -ne 0 ] && [ $PHP_FPM_STATUS -ne 0 ]; then
            exit 0;
       fi
    fi

	sleep 1
done
