FROM ubuntu:18.04
MAINTAINER clamy54
ENV container docker
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TZ="America/New_York"
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

RUN apt update && apt install -y software-properties-common wget sed patch
RUN apt update && apt install -y libapache2-mod-php7.2 php7.2 php7.2-xml php7.2-curl php7.2-gd php7.2-mbstring php7.2-zip php7.2-intl php7.2-opcache php7.2-common php7.2-ldap openssl subversion libapache2-mod-svn less vim wget tzdata && ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

RUN apt install -y python3 python

RUN sed -i 's/^\s*ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf 
RUN sed -i 's/^\s*ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf 
RUN sed -i 's/^\s*SSLProtocol all -SSLv3/SSLProtocol all -TLSv1.1 -TLSv1 -SSLv2 -SSLv3/g' /etc/apache2/mods-available/ssl.conf 
RUN sed -i 's/^\s*SSLCipherSuite HIGH:!aNULL/SSLCipherSuite ALL:+HIGH:!ADH:!EXP:!SSLv2:!SSLv3:!MEDIUM:!LOW:!NULL:!aNULL/g' /etc/apache2/mods-available/ssl.conf 
RUN sed -i 's/^\s*#SSLHonorCipherOrder on/SSLHonorCipherOrder on/g' /etc/apache2/mods-available/ssl.conf 
RUN sed -i 's/^\s*LoadModule dav_module \/usr\/lib\/apache2\/modules\/mod_dav\.so/<IfModule !mod_dav.c>\n  LoadModule dav_module \/usr\/lib\/apache2\/modules\/mod_dav\.so\n<\/IfModule>/g' /etc/apache2/mods-available/dav.load

COPY files/dav_svn.conf  /etc/apache2/mods-available/dav_svn.conf

RUN a2enmod auth_digest && a2enmod dav_svn && a2enmod ssl

RUN mkdir -p /var/svn /etc/apache2/dav_svn /container /var/hooks && chown www-data:www-data /var/svn &&  chown www-data:www-data /var/hooks

COPY files/entrypoint.sh /container/entrypoint.sh

RUN chmod 755 /container/entrypoint.sh 

RUN wget -O /var/www/html/stable-1.6.2.tar.gz https://github.com/mfreiholz/iF.SVNAdmin/archive/refs/tags/stable-1.6.2.tar.gz && cd /var/www/html && rm -f index.html && tar zxf stable-1.6.2.tar.gz --strip 1 && rm -f stable-1.6.2.tar.gz .gitignore && chown -R www-data:www-data /var/www/html/ && chmod 777 /var/www/html/data

COPY files/config.ini /var/www/html/data/config.ini

COPY files/userroleassignments.ini /var/www/html/data/userroleassignments.ini
COPY files/phpversion.patch /tmp

RUN cd /var/www/html && patch -p0 < /tmp/phpversion.patch && rm -f /tmp/phpversion.patch

RUN chown www-data:www-data /var/www/html/data/config.ini /var/www/html/data/userroleassignments.ini

RUN sed -i 's/deny from all/Require all denied/g' /var/www/html/.htaccess && echo "Require all denied" > /var/www/html/data/.htaccess

VOLUME ["/var/svn", "/etc/apache2/dav_svn", "/etc/apache2/keys", "/var/hooks"]

EXPOSE 80 443

HEALTHCHECK --interval=1m --timeout=5s --retries=3 CMD ps aux | grep apache2 | grep www-data || exit 1

ENTRYPOINT ["/container/entrypoint.sh"]

