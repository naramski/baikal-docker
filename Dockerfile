FROM php:8.4-apache

RUN apt update && apt upgrade -y

RUN apt install -y wget unzip

RUN wget -O /tmp/baikal.zip https://github.com/sabre-io/Baikal/releases/download/0.13.0/baikal-0.13.0.zip
RUN unzip /tmp/baikal.zip -d /var/www/

RUN rm -rf /var/www/html && ln -sT /var/www/baikal/html /var/www/html

COPY init-baikal-config.sh /init-baikal-config.sh
RUN chmod +x /init-baikal-config.sh

RUN chown -R www-data:www-data /var/www/baikal

RUN apt-get purge --yes --force-yes --auto-remove wget unzip
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/init-baikal-config.sh"]

CMD ["apache2-foreground"]

