#!/bin/sh
# Written by Brian Gilbert @BrianGilbert_ https://github.com/BrianGilbert

mkdir -p /usr/local/etc/ssl/private;
openssl req -x509 -nodes -days 7300 -subj "/C=US/ST=New York/O=Aegir/OU=Cloud/L=New York/CN=*.aegir.ld" -newkey rsa:2048 -keyout /usr/local/etc/ssl/private/nginx-wild-ssl.key -out /usr/local/etc/ssl/private/nginx-wild-ssl.crt -batch 2> /dev/null;
wget -O /var/aegir/config/server_master/nginx/pre.d/nginx_wild_ssl.conf https://gist.github.com/BrianGilbert/7760457/raw/fa9163ecc533ae14ea1332b38444e03be00dd329/nginx_wild_ssl.conf;
sudo /usr/local/bin/nginx -s reload;
