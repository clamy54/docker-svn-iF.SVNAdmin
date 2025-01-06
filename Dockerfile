FROM ubuntu:24.04
MAINTAINER clamy54
ENV container docker
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TZ="America/New_York"
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

RUN apt update && apt install -y software-properties-common wget build-essential checkinstall libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev
RUN add-apt-repository -y ppa:ondrej/apache2 && add-apt-repository -y ppa:ondrej/php
RUN apt update && apt install -y libapache2-mod-php7.4 php7.4 php7.4-xml php7.4-curl php7.4-gd php7.4-mbstring php7.4-zip php7.4-intl php7.4-opcache php7.4-common php7.4-ldap openssl subversion libapache2-mod-svn less vim wget tzdata && ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

RUN apt install -y python3


RUN cd /usr/local/src && wget https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb && dpkg -i libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb && rm -f libssl1.1_1.1.1f-1ubuntu2.23_amd64.deb

RUN cd /usr/local/src && wget https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2.23_amd64.deb && dpkg -i libssl-dev_1.1.1f-1ubuntu2.23_amd64.deb && rm -f libssl-dev_1.1.1f-1ubuntu2.23_amd64.deb

RUN cd /usr/local/src && wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz && tar -zxf Python-2.7.18.tgz && cd /usr/local/src/Python-2.7.18/ && ./configure --exec-prefix=/usr --sysconfdir=/etc --prefix=/usr --enable-optimizations && make && make install && cd /usr/local/src && rm -rf Python-2.7.18 && rm -f Python-2.7.18.tgz 

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

RUN chown www-data:www-data /var/www/html/data/config.ini /var/www/html/data/userroleassignments.ini

RUN sed -i 's/deny from all/Require all denied/g' /var/www/html/.htaccess && echo "Require all denied" > /var/www/html/data/.htaccess

VOLUME ["/var/svn", "/etc/apache2/dav_svn", "/etc/apache2/keys", "/var/hooks"]

EXPOSE 80 443

HEALTHCHECK --interval=1m --timeout=5s --retries=3 CMD ps aux | grep apache2 | grep www-data || exit 1

ENTRYPOINT ["/container/entrypoint.sh"]

