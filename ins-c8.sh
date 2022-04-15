#!/usr/bin/env bash
# THIS IS PERSONAL SCRIPT, IT MAY NOT WORK ON OTHER SERVERS
# FOR ANY SUGGESTION PLEASE COMMENT BELOW
# Script by https://goranmargetic.com

clear >$(tty)
read -p "Press enter to continue or CTRL+C to exit"

cd /tmp
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
dnf -y install epel-release

dnf -y update && dnf -y upgrade

dnf -y install nano wget unzip

dnf -y install httpd
dnf -y install mod_ssl

systemctl start httpd
systemctl enable httpd

dnf -y install mariadb-server mariadb
systemctl start mariadb

dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm

dnf -y module enable php:remi-7.4
dnf -y install php php-cli php-common
dnf -y install php-pdo php-pecl-zip php-json php-fpm php-mbstring php-mysqlnd php-json
dnf -y install php php-opcache php-mysql
dnf -y install php-gd php-ldap php-odbc php-pear php-xml php-xmlrpc php-soap curl curl-devel

php -v

systemctl restart httpd

wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.zip
unzip phpMyAdmin-5.0.2-all-languages.zip
mv phpMyAdmin-5.0.2-all-languages /usr/share/phpmyadmin
cd /usr/share/phpmyadmin
mv config.sample.inc.php config.inc.php
mkdir /usr/share/phpmyadmin/tmp
chown -R apache:apache /usr/share/phpmyadmin
chmod 777 /usr/share/phpmyadmin/tmp

cat > /etc/httpd/conf.d/phpMyAdmin.conf <<EOL
Alias /pma /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin/>
   AddDefaultCharset UTF-8

   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny> 
      Require all granted
     </RequireAny>
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from All
     Allow from 127.0.0.1
     Allow from ::1
   </IfModule>
</Directory>

<Directory /usr/share/phpmyadmin/setup/>
   <IfModule mod_authz_core.c>
     # Apache 2.4
     <RequireAny>
       Require all granted
     </RequireAny>
   </IfModule>
   <IfModule !mod_authz_core.c>
     # Apache 2.2
     Order Deny,Allow
     Deny from All
     Allow from 127.0.0.1
     Allow from ::1
   </IfModule>
</Directory>
EOL

systemctl restart httpd

echo "";
echo "PhpMyAdmin End";
echo "";

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '8a6138e2a05a8c28539c9f0fb361159823655d7ad2deecb371b04a83966c61223adc522b0189079e3e9e277cd72b8897') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

dnf -y install htop zip

echo ""
echo "Run: mysql_secure_installation"
echo "Run (secret): nano /usr/share/phpmyadmin/config.inc.php"
echo "Run: mysql < /usr/share/phpmyadmin/sql/create_tables.sql -u root -p"

echo "Restart Apache!";
echo "";
