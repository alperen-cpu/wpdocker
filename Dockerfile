FROM php:8.1-fpm
COPY conf/settings.sh /home/
RUN apt update && apt install nano -y && chmod +x /home/settings.sh && bash /home/settings.sh
EXPOSE 9000