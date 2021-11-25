#!/bin/bash

if [ -e "/etc/apache2/keys/cert.pem" ] && [ -e "/etc/apache2/keys/cert.key" ] && [ -e "/etc/apache2/keys/ca.pem" ]
then
    echo "Setting-up apache2-ssl for CA signed certificate"
    cat <<EOF > /etc/apache2/sites-available/ifsvnadmin.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/
    <Directory /var/www/html>
        AllowOverride AuthConfig
    </Directory>
</VirtualHost>
<VirtualHost *:443>
	DocumentRoot /var/www/html/
	SSLEngine On
	SSLCertificateFile /etc/apache2/keys/cert.pem
	SSLCertificateKeyFile /etc/apache2/keys/cert.key
	SSLCertificateChainFile /etc/apache2/keys/ca.pem
	SSLCompression Off
    <Directory /var/www/html>
        AllowOverride AuthConfig
    </Directory>
</VirtualHost>

EOF
else
    if [ ! -e "/etc/apache2/keys/cert.pem" ] || [ ! -e "/etc/apache2/keys/cert.key" ]
    then
        echo "Generating self-signed certificate"
        /bin/rm -f /etc/apache2/keys/cert.pem /etc/apache2/keys/cert.key /etc/apache2/keys/ca.pem
        openssl req -x509 -newkey rsa:4086 -subj "/C=NA/ST=NONE/L=NONE/O=NONE/CN=localhost" -keyout "/etc/apache2/keys/cert.key" -out  "/etc/apache2/keys/cert.pem" -days 3650 -nodes -sha256
    fi
    echo "Setting-up apache2-ssl for self-signed certificate"
    cat <<EOF > /etc/apache2/sites-available/ifsvnadmin.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/
    <Directory /var/www/html>
        AllowOverride AuthConfig
    </Directory>
</VirtualHost>
<VirtualHost *:443>
    DocumentRoot /var/www/html/
    SSLEngine On
    SSLCertificateFile /etc/apache2/keys/cert.pem
    SSLCertificateKeyFile /etc/apache2/keys/cert.key
    SSLCompression Off
    <Directory /var/www/html>
        AllowOverride AuthConfig
    </Directory>
</VirtualHost>

EOF
fi

if [ -e "/etc/apache2/sites-enabled/000-default.conf" ] 
then
    echo "Disabling default apache site"
    a2dissite 000-default.conf
fi

if [ -e "/etc/apache2/sites-enabled/default-ssl.conf" ] 
then
    echo "Disabling default apache ssl site"
    a2dissite default-ssl.conf
fi

if [ ! -e "/etc/apache2/sites-enabled/ifsvnadmin.conf" ] 
then
    echo "Activating ifsvnadmin apache configuration file"
    a2ensite ifsvnadmin.conf
fi

if [ ! -e "/etc/apache2/dav_svn/dav_svn.passwd" ] 
then
    echo "Setting-up default admin:admin account ..."
    echo "admin:SVNServer:828b5ce506494160ed2e4aef2e5e8533" > /etc/apache2/dav_svn/dav_svn.passwd
    chown www-data:www-data /etc/apache2/dav_svn/dav_svn.passwd 
fi

if [ ! -e "/etc/apache2/dav_svn/dav_svn.authz" ] 
then
    touch /etc/apache2/dav_svn/dav_svn.authz 
    chown www-data:www-data /etc/apache2/dav_svn/dav_svn.authz
fi

echo "Starting Apache ..."

/usr/sbin/apache2ctl -D FOREGROUND