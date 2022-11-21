#!/usr/bin/env bash
set -e

##### SECRET CONF #####
#MYSQL_ROOT_PWD="`cat /run/secrets/"$SECRET_NAME"_MYSQL_ROOT_PWD`"
#MYSQL_USER="`cat /run/secrets/"$SECRET_NAME"_MYSQL_USER`"
#MYSQL_USER_PWD="`cat /run/secrets/"$SECRET_NAME"_MYSQL_USER_PWD`"
#MYSQL_USER_DB="`cat /run/secrets/"$SECRET_NAME"_MYSQL_USER_DB`"
#FTP_PASS="`cat /run/secrets/"$SECRET_NAME"_FTP_PASS`"
#FTP_USER="`cat /run/secrets/"$SECRET_NAME"_FTP_USER`"
#SSH_PASS="`cat /run/secrets/"$SECRET_NAME"_SSH_PASS`"
##### SECRET CONF #####
##### Env CONF #####
MYSQL_ROOT_PWD=pCdkejWjqNb8
MYSQL_USER=alperensah
MYSQL_USER_PWD=pCdkejWjqNb8
MYSQL_USER_DB=alperendb
FTP_PASS=pCdkejWjqNb8
FTP_USER=alperensah
SSH_PASS=pCdkejWjqNb8
##### Env CONF #####
##### MySQL CONF #####
MYSQL_ROOT_PWD=${MYSQL_ROOT_PWD:-"mysql"}
MYSQL_USER=${MYSQL_USER:-""}
MYSQL_USER_PWD=${MYSQL_USER_PWD:-""}
MYSQL_USER_DB=${MYSQL_USER_DB:-""}

echo "[i] Kullanıcı Ayarlama."
service mysql start $ sleep 10

echo "[i] Root Parola Ayarlama."
mysql --user=root --password=root -e "use mysql;ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PWD';FLUSH PRIVILEGES;"
#
if [ -n "$MYSQL_USER_DB" ]; then
	echo "[i] Database Oluştur: $MYSQL_USER_DB"
	mysql --user=root --password=$MYSQL_ROOT_PWD -e "CREATE DATABASE $MYSQL_USER_DB;FLUSH PRIVILEGES;"
#
	if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_USER_PWD" ]; then
	echo "[i] Yeni Kulanıcı Oluştur: $MYSQL_USER with password $MYSQL_USER_PWD for new database $MYSQL_USER_DB."
	mysql --user=root --password=$MYSQL_ROOT_PWD -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD';GRANT ALL PRIVILEGES ON $MYSQL_USER_DB.* TO '$MYSQL_USER'@'%';FLUSH PRIVILEGES;"
	else
	echo "[i] Yeni Kullanıcı Oluşturuldu."
	fi
fi
killall mysqld
sleep 5
echo "[i] Ayarlamalar Bitti."
##### MySQL CONF #####
##### OTHER CONF #####
ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
echo "" | useradd -u 2004 -M ${FTP_USER} -d ${HOMEDIR}
echo "${FTP_USER}:${FTP_PASS}" | chpasswd
echo "root:${SSH_PASS}" | chpasswd
##### OTHER CONF #####