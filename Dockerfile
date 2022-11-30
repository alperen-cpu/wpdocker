FROM debian:bullseye-slim

LABEL maintainer="bilgi@alperensah.com"
LABEL build_date="15-11-2022"

#Environment
ENV PHP_VERSION=8.1 \
    #NGINX_VERSION=1.22.1 \
    vhome=/home/web/public_html \
    LANG=C.UTF-8
ENV MYSQL_MAJOR 8.0
ENV MYSQL_VERSION 8.0.31-1debian11
ENV GOSU_VERSION 1.14
ENV TZ=Asia/Istanbul
ENV DEBIAN_FRONTEND noninteractive
#Requirements
RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -yq --no-install-recommends \
    apt-utils \
    curl \
    nano \
    gnupg2 \
    bzip2 \
    gnupg dirmngr \
    software-properties-common \
    unzip \
    zip \
    git \
    vsftpd \
    sudo \
    openssh-server \
    wget \
    htop \
    perl \
    xz-utils \
    zstd \
    openssl \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    debian-archive-keyring \
    && rm -rf /var/lib/apt/lists/*
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
RUN apt-get -y install nginx
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
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates wget; \
	rm -rf /var/lib/apt/lists/*; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

RUN mkdir /docker-entrypoint-initdb.d

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		bzip2 \
		openssl \
# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
# File::Basename
# File::Copy
# Sys::Hostname
# Data::Dumper
		perl \
		xz-utils \
		zstd \
	; \
	rm -rf /var/lib/apt/lists/*

RUN set -eux; \
# gpg: key 3A79BD29: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
	key='859BE8D7C586F538430B19C2467B942D3A79BD29'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	mkdir -p /etc/apt/keyrings; \
	gpg --batch --export "$key" > /etc/apt/keyrings/mysql.gpg; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"
	
RUN echo 'deb [ signed-by=/etc/apt/keyrings/mysql.gpg ] http://repo.mysql.com/apt/debian/ bullseye mysql-8.0' > /etc/apt/sources.list.d/mysql.list

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
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
# ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
	&& chmod 1777 /var/run/mysqld /var/lib/mysql
#MYSQL INSTALL FINISH
####################################################
#Supervisor INSTALL START
RUN apt update && apt install -y supervisor
RUN touch /var/log/supervisor/supervisord.log
RUN chmod 777 /var/log/supervisor/supervisord.log
#RUN chmod 777 /var/run/supervisor/
## Permission denied: '/var/log/supervisor/supervisord.log'
#Supervisor INSTALL FINISH
####################################################
#Config Files
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY config/my.cnf /etc/mysql/
COPY config/vsftpd.conf /etc/vsftpd.conf
COPY config/nginx.conf /etc/nginx/conf.d/nginx.conf
RUN rm -rf /etc/nginx/conf.d/default.conf
COPY scripts/docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
####################################################
#Other
#
RUN useradd -ms /bin/bash superuser
#
RUN sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && sed -i 's/^#Port 22/Port 22/g' /etc/ssh/sshd_config
EXPOSE 22 21 3306 33060 80 443
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld"]
####################################################
VOLUME /home
VOLUME /var/lib/mysql