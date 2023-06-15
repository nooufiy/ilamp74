#!/bin/bash

echo "-"
echo "-"
echo "=============================="
echo "LAMP 7.4 DB Begin Installation"
echo "==============================" 
echo "-"
echo "-"


dpub="sites"
rpas="S3cr3tt9II*"
mail="nooufiy@outlook.com"
mkdir -p /"$dpub"/{w,l}
mkdir -p /rs

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
yum install htop -y
yum install screen -y
yum install dos2unix -y
yum install wget -y
yum -y install nano
yum -y install httpd zip unzip git

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

# Aaspell
# yum -y install php-pspell
# yum install -y aspell-bn aspell-br aspell-ca aspell-cs aspell-cy aspell-da aspell-de aspell-el aspell-en aspell-es aspell-fi aspell-fo aspell-fr aspell-ga aspell-gd aspell-gl aspell-gu aspell-he aspell-hi aspell-hr aspell-id aspell-is aspell-it aspell-la aspell-ml aspell-mr aspell-mt aspell-nl aspell-no aspell-or aspell-pa aspell-pl aspell-pt aspell-ru aspell-sk aspell-sl aspell-sr aspell-sv aspell-ta aspell-te
# aspell dump dicts

yum install -y gcc php-devel php-pear
yum install -y ImageMagick ImageMagick-devel
yes | pecl install imagick
echo "extension=imagick.so" > /etc/php.d/imagick.ini
#systemctl restart httpd.service
convert -version
yum -y install libtool httpd-devel

yum install -y phpmyadmin
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin

# WP
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
# Memindahkan wp-cli.phar ke direktori yang dapat diakses secara global
sudo mv wp-cli.phar /usr/local/bin/wp
# wp --info

cd /tmp
#wget https://www.cloudflare.com/static/misc/mod_cloudflare/mod_cloudflare.c
wget https://raw.githubusercontent.com/cloudflare/mod_cloudflare/master/mod_cloudflare.c
apxs -a -i -c mod_cloudflare.c
wget https://github.com/nooufiy/ilamp74/raw/main/mod_cloudflare.so
mv mod_cloudflare.so /usr/lib64/httpd/modules/
chmod 755 /usr/lib64/httpd/modules/mod_cloudflare.so
# echo "LoadModule cloudflare_module /usr/lib64/httpd/modules/mod_cloudflare.so" >> /etc/httpd/conf.d/cloudflare.conf
chcon -t httpd_modules_t /usr/lib64/httpd/modules/mod_cloudflare.so

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

# chcon -R -t httpd_sys_rw_content_t /"$dpub"
# chcon -R system_u:object_r:httpd_sys_content_t /"$dpub"/{w,l}
# chown -R apache:apache /"$dpub"/{w,l}

vhs="manual" #dinamis/manual

if [ "$vhs" == "manual" ]; then

# Vhost manual
echo "IncludeOptional conf.s/*.conf" >> /etc/httpd/conf/httpd.conf
wget https://github.com/nooufiy/ilamp74/raw/main/vh.sh
mv vh.sh /rs
sed -i "3i email=\"$mail\"" /rs/vh.sh
sed -i "4i home_dir=\"/$dpub/w\"" /rs/vh.sh
chmod +x /rs/vh.sh

script_path="/rs/vh.sh"
service_file="/etc/systemd/system/mysts.service"

cat <<EOF > "$service_file"
[Unit]
Description=Syssts
After=network.target

[Service]
ExecStart=$script_path
Type=simple
Restart=always
StandardOutput=null
StandardError=null

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable mysts.service
systemctl start mysts.service
systemctl status mysts.service
# service httpd restart

else

# Vhost dinamis

sites_dir="/$dpub/w"
apache_conf="/etc/httpd/conf/httpd.conf"

# Mengecek apakah modul vhost_alias sudah diaktifkan
if ! grep -q "LoadModule vhost_alias_module" "$apache_conf"; then
  echo "LoadModule vhost_alias_module modules/mod_vhost_alias.so" | sudo tee -a "$apache_conf" > /dev/null
fi

# Mengaktifkan pengaturan VirtualDocumentRoot
if ! grep -q "VirtualDocumentRoot" "$apache_conf"; then
  echo "VirtualDocumentRoot $sites_dir/%0" | sudo tee -a "$apache_conf" > /dev/null
fi


# Ssl

wget https://github.com/nooufiy/ilamp74/raw/main/ssl.sh
mv ssl.sh /rs

sed -i "3i email=\"$mail\"" /rs/ssl.sh
sed -i "4i home_dir=\"/$dpub/w\"" /rs/ssl.sh
chmod +x /rs/ssl.sh

script_path="/rs/ssl.sh"
service_file="/etc/systemd/system/myssl.service"

cat <<EOF > "$service_file"
[Unit]
Description=Sysssl
After=network.target

[Service]
ExecStart=$script_path
Type=simple
Restart=always
StandardOutput=null
StandardError=null

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload
systemctl enable myssl.service
systemctl start myssl.service
systemctl status myssl.service

fi

wget https://github.com/nooufiy/ilamp74/raw/main/cs.sh
mv cs.sh /rs
sed -i "4i home_dir=\"/$dpub/w\"" /rs/cs.sh
chmod +x /rs/cs.sh


chcon -R -t httpd_sys_rw_content_t "/$dpub"
chcon -R system_u:object_r:httpd_sys_content_t "/$dpub/{w,l}"
chown -R apache:apache "/$dpub"

systemctl start httpd.service
systemctl enable httpd.service
# service httpd restart
service httpd status
service mariadb status

sed -i "4i alias ceklog='sudo tail -f /var/log/httpd/error_log'" ~/.bashrc
source ~/.bashrc
echo ""
echo "== [DONE] =="
echo ""
