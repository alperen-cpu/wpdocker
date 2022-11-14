FROM debian:bullseye-slim

#Environment
ENV PHP_VERSION=8.1 \
    NGINX_VERSION=1.23.2 \
    MYSQL_VERSION=8.0.31-1debian11 \
    MYSQL_MAJOR=8.0

#Requirements
RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    nano \
    gnupg2 \
    software-properties-common \
    unzip \
    zip \
    git \
    vsftpd \
    sudo \
    wget \
    htop \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    debian-archive-keyring \
    && rm -rf /var/lib/apt/lists/* \
####################################################
# NGINX INSTALL START
RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
RUN echo "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > \ | tee /etc/apt/preferences.d/99nginx
RUN cat /etc/apt/preferences.d/99nginx
RUN apt-get -y update
RUN apt-get -y install nginx${NGINX_VERSION}
RUN nginx -v
#NGINX INSTALL FINISH
####################################################
#PHP INSTALL START
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
RUN apt update -y
RUN apt-get install -y php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dom \
    php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    && apt update -y \
    && php -v
#PHP INSTALL FINISH
####################################################
#MYSQL INSTALL START
RUN groupadd -r mysql && useradd -r -g mysql mysql
RUN echo 'deb [ signed-by=/etc/apt/keyrings/mysql.gpg ] http://repo.mysql.com/apt/debian/ bullseye mysql-8.0' > /etc/apt/sources.list.d/mysql.list
RUN { \
		echo mysql-community-server mysql-community-server/data-dir select ''; \
		echo mysql-community-server mysql-community-server/root-pass password ''; \
		echo mysql-community-server mysql-community-server/re-root-pass password ''; \
		echo mysql-community-server mysql-community-server/remove-test-db select false; \
	} | debconf-set-selections \
	&& apt-get update \
	&& apt-get install -y \
		mysql-community-client="${MYSQL_VERSION}" \
		mysql-community-server-core="${MYSQL_VERSION}" \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
	&& chmod 1777 /var/run/mysqld /var/lib/mysql

VOLUME /var/lib/mysql
#MYSQL INSTALL FINISH
####################################################
#Config Files
COPY config/ /etc/mysql/
COPY scripts/docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
####################################################
#Other
EXPOSE 22 21 3306 80 443
CMD ["mysqld"]
####################################################