#!/bin/bash
sed -i 's/listen.owner \= www-data/listen.owner \= nginx/g' /usr/local/etc/php-fpm.d/www.conf && sed -i 's/listen.group \= www-data/listen.group \= nginx/g' /usr/local/etc/php-fpm.d/www.conf