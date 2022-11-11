FROM php:8.1-fpm
COPY conf/settings.sh /home/
RUN apt update && apt install nano -y && chmod +x /home/settings.sh && bash /home/settings.sh
RUN apt update && apt install net-tools -y && apt-get install iputils-ping -y && apt install nano -y
RUN apt-get install -y zlib1g-dev libpng-dev libzip-dev
RUN apt-get update && apt-get install -y \
    libmagickwand-dev --no-install-recommends \
    && pecl install imagick \
	&& docker-php-ext-enable imagick
RUN docker-php-ext-install mysqli pdo_mysql gd zip pcntl exif "error imagick modules" imagick intl
RUN docker-php-ext-enable mysqli pdo_mysql gd zip pcntl exif imagick intl
EXPOSE 9000