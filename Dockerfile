FROM debian:bullseye-slim

LABEL maintainer="bilgi@alperensah.com"
LABEL build_date="15-11-2022"

#Environment
ENV PHP_VERSION=8.1 \
    MYSQL_VERSION=8.0.31-1debian11 \
    MYSQL_MAJOR=8.0 \
    #NGINX_VERSION=1.22.1 \
    vhome=/home/web/public_html \
    LANG=C.UTF-8
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
    openssh-server \
    wget \
    htop \
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
RUN echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections
RUN set -eux; \
# gpg: key 3A79BD29: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
	key='859BE8D7C586F538430B19C2467B942D3A79BD29'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	mkdir -p /etc/apt/keyrings; \
	gpg --batch --export "$key" > /etc/apt/keyrings/mysql.gpg; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"
RUN groupadd -r mysql && useradd -r -g mysql mysql
RUN echo 'deb [ signed-by=/etc/apt/keyrings/mysql.gpg ] http://repo.mysql.com/apt/debian/ bullseye mysql-8.0' > /etc/apt/sources.list.d/mysql.list
RUN apt-get update \
	&& apt-get install -y \
		mysql-community-client="${MYSQL_VERSION}" \
		mysql-community-server-core="${MYSQL_VERSION}" \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
	&& chmod 1777 /var/run/mysqld /var/lib/mysql
RUN sed -i -e "$ a [client]\n\n[mysql]\n\n[mysqld]"  /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[client\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[mysql\]\)/\1\ndefault-character-set = utf8/g" /etc/mysql/my.cnf && \
	sed -i -e "s/\(\[mysqld\]\)/\1\ninit_connect='SET NAMES utf8'\ncharacter-set-server = utf8\ncollation-server=utf8_unicode_ci\nbind-address = 0.0.0.0/g" /etc/mysql/my.cnf    
#MYSQL INSTALL FINISH
####################################################
#Config Files
COPY config/my.cnf /etc/mysql/
COPY config/vsftpd.conf /etc/vsftpd.conf
COPY scripts/docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh
####################################################
#Other
RUN sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && sed -i 's/^#Port 22/Port 22/g' /etc/ssh/sshd_config
EXPOSE 22 21 3306 80 443
ENTRYPOINT ["docker-entrypoint.sh"]
CMD [ "/usr/bin/mysqld_safe" ]
####################################################
VOLUME /home
VOLUME /var/lib/mysql