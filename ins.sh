#!/bin/bash

echo "-"
echo "-"
echo "==========================="
echo "LAMP 7.4 Begin Installation"
echo "===========================" 
echo "-"
echo "-"

yum install screen -y
yum -y install nano
yum -y install httpd zip unzip git
systemctl start httpd.service
systemctl enable httpd.service
mkdir /home/{w,l}
> /home/w/index.php
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
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install yum-utils
yum -y update
yum-config-manager --enable remi-php74
yum -y install php php-opcache
systemctl restart httpd.service
yum install -y php74-php-cli.x86_64 php74-php-fpm.x86_64 php74-php-gd.x86_64 php74-php-geos.x86_64 php74-php-json.x86_64 php74-php-mbstring.x86_64 php74-php-mcrypt.x86_64 php74-php-opcache.x86_64 php74-php-xml.x86_64 php74-php-xmlrpc.x86_64
systemctl restart httpd.service
php -v
yum -y install php-pspell
yum install -y aspell-bn aspell-br aspell-ca aspell-cs aspell-cy aspell-da aspell-de aspell-el aspell-en aspell-es aspell-fi aspell-fo aspell-fr aspell-ga aspell-gd aspell-gl aspell-gu aspell-he aspell-hi aspell-hr aspell-id aspell-is aspell-it aspell-la aspell-ml aspell-mr aspell-mt aspell-nl aspell-no aspell-or aspell-pa aspell-pl aspell-pt aspell-ru aspell-sk aspell-sl aspell-sr aspell-sv aspell-ta aspell-te
aspell dump dicts
yum install -y gcc php-devel php-pear
yum install -y ImageMagick ImageMagick-devel
yes | pecl install imagick
echo "extension=imagick.so" > /etc/php.d/imagick.ini
systemctl restart httpd.service
convert -version
yum -y install libtool httpd-devel
cd /tmp
#wget https://www.cloudflare.com/static/misc/mod_cloudflare/mod_cloudflare.c
wget https://raw.githubusercontent.com/cloudflare/mod_cloudflare/master/mod_cloudflare.c
apxs -a -i -c mod_cloudflare.c
chmod 755 /usr/lib64/httpd/modules/mod_cloudflare.so
wget https://github.com/nooufiy/ilamp74/raw/main/mod_cloudflare.so
mv mod_cloudflare.so /usr/lib64/httpd/modules/
echo "LoadModule cloudflare_module /usr/lib64/httpd/modules/mod_cloudflare.so" >> /etc/httpd/conf.d/cloudflare.conf
systemctl restart httpd.service
yum -y install logrotate
mv /etc/logrotate.d/httpd /etc/logrotate.d/httpd.bak
cd /etc/logrotate.d
wget https://raw.githubusercontent.com/nooufiy/ilamp81/main/httpd
sed -i "s/\/var\/www\/html/\/home\/w/g" /etc/httpd/conf/httpd.conf
chcon -R -t httpd_sys_rw_content_t /home
chcon -R system_u:object_r:httpd_sys_content_t /home/w
systemctl restart httpd.service
