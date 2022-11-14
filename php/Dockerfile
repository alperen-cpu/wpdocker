FROM php:8.1-fpm
RUN sed -i 's/listen.owner \= www-data/listen.owner \= nginx/g' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/listen.group \= www-data/listen.group \= nginx/g' /usr/local/etc/php-fpm.d/www.conf
RUN apt-get update && apt-get install -y \
    libmagickwand-dev --no-install-recommends \
    && pecl install imagick
RUN apt-get install -y zlib1g-dev libpng-dev libzip-dev    
RUN docker-php-ext-install mysqli pdo_mysql gd zip pcntl exif intl
RUN docker-php-ext-enable mysqli pdo_mysql gd zip pcntl exif imagick intl
EXPOSE 9000