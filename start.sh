#!/bin/bash
set -e

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
	mysql --user=root --password=$MYSQL_ROOT_PWD -e "use $MYSQL_USER_DB;CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_USER_PWD';GRANT ALL PRIVILEGES ON $MYSQL_USER_DB.* TO '$MYSQL_USER'@'%';FLUSH PRIVILEGES;"
	else
	echo "[i] Yeni Kullanıcı Oluşturuldu."
	fi
fi
killall mysqld
sleep 5
echo "[i] Ayarlamalar Bitti."

exec "$@"
