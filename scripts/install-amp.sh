#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# based on https://github.com/laravel/homestead

BOX_NAME="phpstorm.box"
BOX_DOCROOT="/vagrant/public"
BOX_DBPASS="vagrant"

# Update Package List
apt-get update

# Update System Packages
apt-get -y upgrade

# Force Locale
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8

# Install Some Basic Packages
apt-get install -y build-essential software-properties-common curl dos2unix gcc git libmcrypt4 \
libpcre3-dev ntp unzip make python2.7-dev python-pip re2c supervisor unattended-upgrades whois \
vim libnotify-bin pv cifs-utils

# Set My Timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Install AMP

debconf-set-selections <<< "mysql-server mysql-server/root_password password $BOX_DBPASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $BOX_DBPASS"

# @todo: apache-http2
#apt-add-repository ppa:ondrej/apache2 -y
apt-add-repository ppa:ondrej/php -y
apt-add-repository ppa:chris-lea/redis-server -y
apt-add-repository ppa:chris-lea/libsodium -y
add-apt-repository ppa:mapopa/firebird3.0 -y

apt-get update

apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
apache2 libapache2-mod-php7.1 \
php7.1-cli php7.1-dev \
php7.1-gd php7.1-curl php7.1-imap php7.1-mbstring \
php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
php7.1-intl php7.1-readline php-xdebug \
php7.1-mysql mysql-server \
php7.1-memcached memcached \
php7.1-pgsql postgresql \
php7.1-sqlite3 sqlite3 libsqlite3-dev \
php7.1-interbase firebird2.5-superclassic \
php7.1-imagick imagemagick \
redis-server libsodium-dev

# Setup Some PHP-FPM Options
echo "xdebug.remote_enable = 1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php/7.1/mods-available/xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php/7.1/mods-available/xdebug.ini
echo "opcache.revalidate_freq = 0" >> /etc/php/7.1/mods-available/opcache.ini

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/apache2/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/apache2/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.1/apache2/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.1/apache2/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.1/apache2/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/apache2/php.ini

# Set Some PHP CLI Settings
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 1G/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
printf "\nPATH=\"$(sudo su - vagrant -c 'composer config -g home 2>/dev/null')/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.profile

# Install global PHPUnit
wget https://phar.phpunit.de/phpunit.phar
chmod +x phpunit.phar
mv phpunit.phar /usr/local/bin/phpunit
phpunit --version

# Install Libsodium extension
pecl channel-update pecl.php.net
pecl install libsodium

echo "extension=libsodium.so" > /etc/php/7.1/mods-available/libsodium.ini

ln -sf /etc/php/7.1/mods-available/libsodium.ini /etc/php/7.1/apache2/conf.d/20-libsodium.ini
ln -sf /etc/php/7.1/mods-available/libsodium.ini /etc/php/7.1/cli/conf.d/20-libsodium.ini

# PHPRedis
git clone https://github.com/phpredis/phpredis.git
cd phpredis && git checkout php7 && phpize && ./configure && make && make install
cd .. && rm -rf phpredis

echo "extension=redis.so" > /etc/php/7.1/mods-available/redis.ini

ln -sf /etc/php/7.1/mods-available/redis.ini /etc/php/7.1/apache2/conf.d/20-redis.ini
ln -sf /etc/php/7.1/mods-available/redis.ini /etc/php/7.1/cli/conf.d/20-redis.ini

# APCU
pecl install apcu

echo "extension=apcu.so" > /etc/php/7.1/mods-available/apcu.ini
echo "apc.enable=1" >> /etc/php/7.1/mods-available/apcu.ini
echo "apc.enable_cli=1" >> /etc/php/7.1/mods-available/apcu.ini

ln -sf /etc/php/7.1/mods-available/apcu.ini /etc/php/7.1/apache2/conf.d/20-apcu.ini
ln -sf /etc/php/7.1/mods-available/apcu.ini /etc/php/7.1/cli/conf.d/20-apcu.ini

# Configure Postgres Remote Access
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.5/main/postgresql.conf
echo "host    all             all             10.0.2.2/32               md5" | tee -a /etc/postgresql/9.5/main/pg_hba.conf
sudo -u postgres psql -c "CREATE ROLE vagrant LOGIN UNENCRYPTED PASSWORD '$BOX_DBPASS' SUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;"
sudo -u postgres /usr/bin/createdb --echo --owner=vagrant vagrant
service postgresql restart

# Configure MySQL Password Lifetime
echo "default_password_lifetime = 0" >> /etc/mysql/mysql.conf.d/mysqld.cnf

# Configure MySQL Remote Access
sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
mysql --user="root" --password="$BOX_DBPASS" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY '$BOX_DBPASS' WITH GRANT OPTION;"
service mysql restart
mysql --user="root" --password="$BOX_DBPASS" -e "CREATE USER 'vagrant'@'0.0.0.0' IDENTIFIED BY '$BOX_DBPASS';"
mysql --user="root" --password="$BOX_DBPASS" -e "GRANT ALL ON *.* TO 'vagrant'@'0.0.0.0' IDENTIFIED BY '$BOX_DBPASS' WITH GRANT OPTION;"
mysql --user="root" --password="$BOX_DBPASS" -e "GRANT ALL ON *.* TO 'vagrant'@'%' IDENTIFIED BY '$BOX_DBPASS' WITH GRANT OPTION;"
mysql --user="root" --password="$BOX_DBPASS" -e "FLUSH PRIVILEGES;"
mysql --user="root" --password="$BOX_DBPASS" -e "CREATE DATABASE vagrant character set UTF8mb4 collate utf8mb4_bin;"
service mysql restart

# PHPMyAdmin
wget https://files.phpmyadmin.net/phpMyAdmin/4.7.1/phpMyAdmin-4.7.1-all-languages.tar.gz
tar -xzvf phpMyAdmin-4.7.1-all-languages.tar.gz -C /usr/share/
mv /usr/share/phpMyAdmin-4.7.1-all-languages /usr/share/phpmyadmin
cd /usr/share/phpmyadmin/ && composer install --no-dev --no-interaction --prefer-dist
cd /home/vagrant && rm phpMyAdmin-4.7.1-all-languages.tar.gz

CONFIG_PHPMYADMIN="<?php

\$cfg['blowfish_secret'] = 'YOU MUST FILL IN THIS FOR COOKIE';
\$cfg['DefaultLang'] = 'en';
\$cfg['ShowAll'] = true;
\$cfg['MaxRows'] = 100;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
\$cfg['SendErrorReports'] = 'never';
\$cfg['Servers'][1]['auth_type'] = 'cookie';
\$cfg['Servers'][1]['host'] = 'localhost';
\$cfg['Servers'][1]['connect_type'] = 'tcp';
\$cfg['Servers'][1]['compress'] = false;
\$cfg['Servers'][1]['AllowNoPassword'] = false;

"

echo "$CONFIG_PHPMYADMIN" > "/usr/share/phpmyadmin/config.inc.php"

ALIAS_PHPMYADMIN="Alias /phpmyadmin "/usr/share/phpmyadmin/"
<Directory "/usr/share/phpmyadmin/">
     Order allow,deny
     Allow from all
     Require all granted
</Directory>
"

echo "$ALIAS_PHPMYADMIN" >> "/etc/apache2/conf-available/$BOX_NAME-aliases.conf"

# Configure Firebird
dpkg-reconfigure firebird2.5

CONFIG_FIREBIRD="
ServerMode = SuperClassic
DatabaseAccess = Full
ExternalFileAccess = Full
UdfAccess = Full
"
echo "$CONFIG_FIREBIRD" >> "/etc/firebird/2.5/firebird.conf"

git clone https://github.com/mariuz/firebirdwebadmin.git /usr/share/firebirdwebadmin/

mkdir /home/vagrant/.firebird/
cp /vagrant/config/firebirdwebadmin.config.php /usr/share/firebirdwebadmin/inc/configuration.inc.php

ALIAS_FBWEBADMIN="Alias /firebirdwebadmin "/usr/share/firebirdwebadmin/"
<Directory "/usr/share/firebirdwebadmin/">
     Order allow,deny
     Allow from all
     Require all granted
</Directory>
"

echo "$ALIAS_FBWEBADMIN" >> "/etc/apache2/conf-available/$BOX_NAME-aliases.conf"

# Apache
sed -i "s/www-data/vagrant/" /etc/apache2/envvars

PATH_SSL="/home/vagrant/.ssl"
PATH_CNF="${PATH_SSL}/${BOX_NAME}.cnf"
PATH_KEY="${PATH_SSL}/${BOX_NAME}.key"
PATH_CRT="${PATH_SSL}/${BOX_NAME}.crt"

mkdir "$PATH_SSL" 2>/dev/null

# Uncomment the global 'copy_extentions' OpenSSL option to ensure the SANs are copied into the certificate.
sed -i '/copy_extensions\ =\ copy/s/^#\ //g' /etc/ssl/openssl.cnf

# Generate an OpenSSL configuration file specifically for this certificate.
BOX_SSL_CERT="
[ req ]
prompt = no
default_bits = 2048
default_keyfile = $PATH_KEY
encrypt_key = no
default_md = sha256
distinguished_name = req_distinguished_name
x509_extensions = v3_ca

[ req_distinguished_name ]
O=Vagrant
C=UN
CN=$BOX_NAME

[ v3_ca ]
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alternate_names

[ alternate_names ]
DNS.1 = $BOX_NAME
"
echo "$BOX_SSL_CERT" > $PATH_CNF

# Finally, generate the private key and certificate.
openssl genrsa -out "$PATH_KEY" 2048 2>/dev/null
openssl req -new -x509 -config "$PATH_CNF" -out "$PATH_CRT" -days 365 2>/dev/null

BOX_DEFAULT_HOST="<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot $BOX_DOCROOT

    <Directory $BOX_DOCROOT>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$BOX_NAME-error.log
    CustomLog \${APACHE_LOG_DIR}/$BOX_NAME-access.log combined

    Include conf-available/$BOX_NAME-aliases.conf
</VirtualHost>
"

echo "$BOX_DEFAULT_HOST" > "/etc/apache2/sites-available/$BOX_NAME.conf"
ln -fs "/etc/apache2/sites-available/$BOX_NAME.conf" "/etc/apache2/sites-enabled/$BOX_NAME.conf"

BOX_SSL="<IfModule mod_ssl.c>
    <VirtualHost *:443>
        ServerAdmin webmaster@localhost
        DocumentRoot $BOX_DOCROOT

        <Directory $BOX_DOCROOT>
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

        SSLEngine on

        SSLCertificateFile      $PATH_SSL/$BOX_NAME.crt
        SSLCertificateKeyFile   $PATH_SSL/$BOX_NAME.key

        <FilesMatch \"\.(cgi|shtml|phtml|php)$\">
            SSLOptions +StdEnvVars
        </FilesMatch>
        <Directory /usr/lib/cgi-bin>
            SSLOptions +StdEnvVars
        </Directory>

        Include conf-available/$BOX_NAME-aliases.conf
    </VirtualHost>
</IfModule>
"

echo "$BOX_SSL" > "/etc/apache2/sites-available/$BOX_NAME-ssl.conf"
ln -fs "/etc/apache2/sites-available/$BOX_NAME-ssl.conf" "/etc/apache2/sites-enabled/$BOX_NAME-ssl.conf"

a2dissite 000-default
a2enmod ssl

ps auxw | grep apache2 | grep -v grep > /dev/null

if [ $? == 0 ]
then
    service apache2 reload
fi


# Install & Configure MailHog

wget --quiet -O /usr/local/bin/mailhog https://github.com/mailhog/MailHog/releases/download/v0.2.1/MailHog_linux_amd64
chmod +x /usr/local/bin/mailhog

sudo tee /etc/systemd/system/mailhog.service <<EOL
[Unit]
Description=Mailhog
After=network.target

[Service]
User=vagrant
ExecStart=/usr/bin/env /usr/local/bin/mailhog > /dev/null 2>&1 &

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable mailhog

# Configure Supervisor

systemctl enable supervisor.service
service supervisor start

# Install ngrok

wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip ngrok-stable-linux-amd64.zip -d /usr/local/bin
rm -rf ngrok-stable-linux-amd64.zip

# Clean Up

apt-get -y autoremove
apt-get -y clean

# Enable Swap Memory

/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
/sbin/mkswap /var/swap.1
/sbin/swapon /var/swap.1

# Minimize The Disk Image

echo "Minimizing disk image..."
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync
