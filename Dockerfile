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
RUN curl -o /tmp/mysql.deb https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb
RUN echo mysql-apt-config mysql-apt-config/select-server select mysql-8.0 | debconf-set-selections
RUN echo mysql-community-server mysql-community-server/root-pass '' rot | debconf-set-selections
RUN echo mysql-community-server mysql-community-server/re-root-pass '' rot | debconf-set-selections
RUN dpkg -i /tmp/mysql.deb
RUN apt-get update
RUN apt-get -y install mysql-server mysql-client   
#MYSQL INSTALL FINISH
####################################################
#Config Files
COPY config/my.cnf /etc/mysql/
COPY config/vsftpd.conf /etc/vsftpd.conf
COPY scripts/docker-entrypoint.sh /usr/local/bin/
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
####################################################
#Other
RUN sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config && sed -i 's/^#Port 22/Port 22/g' /etc/ssh/sshd_config
EXPOSE 22 21 3306 33060 80 443
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["mysqld"]
####################################################
VOLUME /home
VOLUME /var/lib/mysql