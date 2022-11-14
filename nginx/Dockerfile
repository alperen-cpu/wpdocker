FROM nginx
RUN rm -rf /usr/share/nginx/html/*
RUN apt update && apt install -y wget unzip && wget https://wordpress.org/latest.zip -P /usr/share/nginx/html/ && unzip /usr/share/nginx/html/latest.zip -d "/usr/share/nginx/html/"
RUN mv /usr/share/nginx/html/wordpress/* /usr/share/nginx/html/ && rm -rf /usr/share/nginx/html/wordpress /usr/share/nginx/html/latest.zip
RUN chown -R www-data:www-data /usr/share/nginx/html
EXPOSE 80