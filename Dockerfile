FROM php:8.1-fpm
COPY conf/settings.sh /home/
RUN apt update && apt install nano -y && chmod +x /home/settings.sh && bash /home/settings.sh
RUN apt update && apt install net-tools -y && apt-get install iputils-ping -y && apt install nano -y
EXPOSE 9000