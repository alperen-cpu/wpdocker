![Logo](https://s.w.org/style/images/about/WordPress-logotype-alternative.png)
# Docker Ubuntu to PHP8.1 MySQL 8.0 Wordpress 

<b>What is the WordPress?</b><br>
WordPress is a free and open source blogging tool and a content management system (CMS) based on PHP and MySQL, which runs on a web hosting service.<br>

<b>DockerHub</b><br>
hub.docker.com/r/alperensah/wpdocker 
## Kullanım/Örnekler

```
docker build -t imagename .
```
```
$ docker run -d -p 3306:3306 -p 80:80 -e "MYSQL_ROOT_PWD=" -e "MYSQL_USER=" -e "MYSQL_USER_PWD=" -e "MYSQL_USER_DB=" imagename
```

  
## Geri Bildirim

Herhangi bir geri bildiriminiz varsa, bilgi@alperensah.com adresinden bana ulaşın.

 
