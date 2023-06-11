#!/bin/bash

echo "-"
echo "-"
echo "==========================="
echo "LAMP 7.4 Begin Installation"
echo "===========================" 
echo "-"
echo "-"

yum install screen -y
yum install wget -y
yum -y install nano
yum -y install httpd zip unzip git
systemctl start httpd.service
systemctl enable httpd.service
dpub="sites"
mkdir -p /"$dpub"/{w,l}
mkdir -p /rs
wget https://github.com/nooufiy/ilamp74/raw/main/vh.sh
sed -i "4i home_dir=\"/\$dpub/w\"" vs.sh
mv vh.sh /rs

> /"$dpub"/w/index.php
# mv /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.bak
# nano /etc/httpd/conf/httpd.conf
# hostnamectl set-hostname dc-001.justinn.ga
systemctl restart systemd-hostnamed
hostnamectl status
yum -y install firewalld
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum -y install epel-release
yum -y install certbot python2-certbot-apache mod_ssl
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils
yum -y update
yum install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb
yum -y install expect

# Set variables for mysql_secure_installation
rpas="S3cr3tt9II*"

# Run mysql_secure_installation with autofill
expect <<EOF
spawn mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Set root password?"
send "Y\r"
expect "New password:"
send "$rpas\r"
expect "Re-enter new password:"
send "$rpas\r"
expect "Remove anonymous users?"
send "Y\r"
expect "Disallow root login remotely?"
send "N\r"
expect "Remove test database and access to it?"
send "Y\r"
expect "Reload privilege tables now?"
send "Y\r"
expect eof
EOF

yum-config-manager --enable remi-php74
yum -y install php php-opcache
#systemctl restart httpd.service
yum install -y php74-php-cli.x86_64 php74-php-fpm.x86_64 php74-php-gd.x86_64 php74-php-geos.x86_64 php74-php-json.x86_64 php74-php-mbstring.x86_64 php74-php-mcrypt.x86_64 php74-php-opcache.x86_64 php74-php-xml.x86_64 php74-php-xmlrpc.x86_64
#systemctl restart httpd.service
php -v
yum -y install php-pspell
yum install -y aspell-bn aspell-br aspell-ca aspell-cs aspell-cy aspell-da aspell-de aspell-el aspell-en aspell-es aspell-fi aspell-fo aspell-fr aspell-ga aspell-gd aspell-gl aspell-gu aspell-he aspell-hi aspell-hr aspell-id aspell-is aspell-it aspell-la aspell-ml aspell-mr aspell-mt aspell-nl aspell-no aspell-or aspell-pa aspell-pl aspell-pt aspell-ru aspell-sk aspell-sl aspell-sr aspell-sv aspell-ta aspell-te
aspell dump dicts
yum install -y gcc php-devel php-pear
yum install -y ImageMagick ImageMagick-devel
yes | pecl install imagick
echo "extension=imagick.so" > /etc/php.d/imagick.ini
#systemctl restart httpd.service
convert -version
yum -y install libtool httpd-devel

yum install -y phpmyadmin
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

cd /tmp
#wget https://www.cloudflare.com/static/misc/mod_cloudflare/mod_cloudflare.c
wget https://raw.githubusercontent.com/cloudflare/mod_cloudflare/master/mod_cloudflare.c
apxs -a -i -c mod_cloudflare.c
chmod 755 /usr/lib64/httpd/modules/mod_cloudflare.so
wget https://github.com/nooufiy/ilamp74/raw/main/mod_cloudflare.so
mv mod_cloudflare.so /usr/lib64/httpd/modules/
echo "LoadModule cloudflare_module /usr/lib64/httpd/modules/mod_cloudflare.so" >> /etc/httpd/conf.d/cloudflare.conf
#systemctl restart httpd.service

yum -y install logrotate
mv /etc/logrotate.d/httpd /etc/logrotate.d/httpd.bak
#cd /etc/logrotate.d
#wget https://raw.githubusercontent.com/nooufiy/ilamp81/main/httpd
echo "/$dpub/l/access_log
/$dpub/l/ssl_request_log
/$dpub/l/ssl_access_log
/$dpub/l/error_log
/$dpub/l/ssl_error_log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        /bin/systemctl reload httpd >/dev/null 2>&1 || true
    endscript
}" > /etc/logrotate.d/httpd

# sed -i "s/\/var\/www\/html/\/$dpub\/w/g" /etc/httpd/conf/httpd.conf
sed -i 's/\/var\/www\/html/\/'"$dpub"'\/w/g' /etc/httpd/conf/httpd.conf

chcon -R -t httpd_sys_rw_content_t /"$dpub"
chcon -R system_u:object_r:httpd_sys_content_t /"$dpub"/{w,l}
chown -R apache:apache /"$dpub"/{w,l}
systemctl restart httpd.service

