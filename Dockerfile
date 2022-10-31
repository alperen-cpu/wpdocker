FROM ubuntu:latest

ENV PHP_VERSION=8.1

RUN echo "deb http://cn.archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse" >> /etc/apt/sources.list


RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    nano \
    gnupg2 \
    software-properties-common \
    unzip \
    sudo \
    wget \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    ubuntu-keyring
    #nginx install start
RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
RUN echo "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > \ | tee /etc/apt/preferences.d/99nginx
RUN cat /etc/apt/preferences.d/99nginx
RUN apt-get -y update
RUN apt-get -y install nginx
RUN nginx -v
RUN rm -rf /etc/nginx/conf.d/default.conf
COPY conf/nginx.conf /etc/nginx/conf.d/
RUN echo "Nginx Install OK"
    #nginx install finish
    #php8.1 install start
ENV TZ=Asia/Istanbul \
    DEBIAN_FRONTEND=noninteractive
RUN add-apt-repository -y ppa:ondrej/nginx-mainline \
    && apt-get install -y php${PHP_VERSION} \
    && php -v
    #php8.1 install finish
    #php8.1 modules start
RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-mysql
    #php8.1 modules finish
RUN sed -i 's/listen.owner \= www-data/listen.owner \= nginx/g' /etc/php/8.1/fpm/pool.d/www.conf
RUN sed -i 's/listen.group \= www-data/listen.group \= nginx/g' /etc/php/8.1/fpm/pool.d/www.conf
    #mysql install start
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections

RUN apt-get update && \
    apt-get -y install mysql-server \
    && chown -R mysql:mysql /var/log/mysql

RUN sed -i -e "$ a [client]\n\n[mysql]\n\n[mysqld]"  /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[client\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[mysql\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[mysqld\]\)/\1\ninit_connect='SET NAMES utf8'\ncharacter-set-server = utf8\ncollation-server=utf8_unicode_ci\nbind-address = 0.0.0.0/g" /etc/mysql/my.cnf

VOLUME /var/lib/mysql
#mysql install finish
#other settings
ADD start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]

EXPOSE 3306 80

CMD ["/usr/bin/mysqld_safe"]

RUN rm -rf /usr/share/nginx/html

COPY html /usr/share/nginx/html

RUN chown -R www-data:www-data /var/cache/nginx \
&& chown -R www-data:www-data /var/log/nginx \
&& chown -R www-data:www-data /usr/share/nginx \
&& chown -R www-data:www-data /etc/nginx \
&& touch /var/run/nginx.pid \
&& chown -R www-data:www-data /var/run/nginx.pid \
&& touch /var/log/php-fpm.log \
&& chown -R www-data:www-data /var/log/php-fpm.log
