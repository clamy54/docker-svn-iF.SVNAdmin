FROM ubuntu/apache2:2.4-20.04_beta
MAINTAINER clamy54
ENV container docker
ENV LANG C.UTF-8

RUN apt update && apt install -y libapache2-mod-php7.4 php7.4 openssl subversion libapache2-mod-svn php7.4-ldap php7.4-xml wget

RUN apt install -y python2

RUN sed -i 's/^\s*ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf 
RUN sed -i 's/^\s*ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf 
RUN sed -i 's/^\s*SSLProtocol all -SSLv3/SSLProtocol all -TLSv1.1 -TLSv1 -SSLv2 -SSLv3/g' /etc/apache2/mods-available/ssl.conf 
RUN sed -i 's/^\s*SSLCipherSuite HIGH:!aNULL/SSLCipherSuite ALL:+HIGH:!ADH:!EXP:!SSLv2:!SSLv3:!MEDIUM:!LOW:!NULL:!aNULL/g' /etc/apache2/mods-available/ssl.conf 
RUN sed -i 's/^\s*#SSLHonorCipherOrder on/SSLHonorCipherOrder on/g' /etc/apache2/mods-available/ssl.conf 

COPY files/dav_svn.conf  /etc/apache2/mods-available/dav_svn.conf

RUN a2enmod auth_digest && a2enmod dav_svn && a2enmod ssl

RUN mkdir -p /var/svn /etc/apache2/dav_svn /container && chown www-data:www-data /var/svn

COPY files/entrypoint.sh /container/entrypoint.sh

RUN chmod 755 /container/entrypoint.sh 

RUN wget -O /var/www/html/stable-1.6.2.tar.gz https://github.com/mfreiholz/iF.SVNAdmin/archive/refs/tags/stable-1.6.2.tar.gz && cd /var/www/html && rm -f index.html && tar zxf stable-1.6.2.tar.gz --strip 1 && rm -f stable-1.6.2.tar.gz .gitignore && chown -R www-data:www-data /var/www/html/ && chmod 777 /var/www/html/data

COPY files/config.ini /var/www/html/data/config.ini

COPY files/userroleassignments.ini /var/www/html/data/userroleassignments.ini

RUN chown www-data:www-data /var/www/html/data/config.ini /var/www/html/data/userroleassignments.ini

RUN sed -i 's/deny from all/Require all denied/g' /var/www/html/.htaccess && echo "Require all denied" > /var/www/html/data/.htaccess

VOLUME ["/var/svn", "/etc/apache2/dav_svn", "/etc/apache2/keys"]

EXPOSE 80 443

HEALTHCHECK --interval=1m --timeout=5s --retries=3 CMD ps aux | grep apache2 | grep www-data || exit 1

ENTRYPOINT ["/container/entrypoint.sh"]
