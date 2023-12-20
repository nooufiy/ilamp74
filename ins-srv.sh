#!/bin/bash

start_time=$(date +%s)

echo "-"
echo "-"
echo "============================"
echo "LAMP & DB Begin Installation"
echo "============================"
echo "-"
echo "-"

rpas="S3cr3tt9II*"
email="nooufiy@outlook.com"
nuser="admin"
aport=7771
dpub="/sites"
ds="/rs"
cs_sh="$ds/cs.sh"
vh_sh="$ds/vh.sh"
ssl_sh="$ds/ssl.sh"
mkdir -p "$dpub"/{w,l,d}
mkdir -p "$ds/ssl"
mkdir -p "$ds/r"

>"$dpub"/w/index.html
>"$dpub"/d/index.html

# SET HOST
# =========
# hostnamectl set-hostname dc-001.justinn.ga
# systemctl restart systemd-hostnamed
# hostnamectl status

# GET DATA
# =========
yusr=$(cat /root/u.txt)
trimmed=$(echo "$yusr" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/"//g')
IFS="_" read -r ip user userid status url rurl phpv <<<"$trimmed"

# USER LNX
# =========
userpas="rhasi4A911*"
adduser "$nuser"
usermod -a -G apache "$nuser"
chown -R apache:apache "$dpub"/{w,d,l}
chmod -R 770 "$dpub"/w
echo "cd $dpub/w" >>/home/"$nuser"/.bashrc
chown "$nuser:$nuser" /home/"$nuser"/.bashrc
echo "$nuser:$userpas" | chpasswd

# iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum install epel-release -y
yum install certbot python2-certbot-apache mod_ssl -y
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install yum-utils -y
yum update -y

# UTILITY
# =======
yum install expect -y
yum install htop -y
yum install screen -y
yum install dos2unix -y
yum install wget -y
yum install nano -y
yum install zip -y
yum install unzip -y
yum install git -y

# HTTPD
# ======
yum install httpd -y
diridx="DirectoryIndex index.html"
sed -i "s/$diridx/$diridx index.php/g" /etc/httpd/conf/httpd.conf

# MARIADB
# =======
# yum install mariadb-server -y
# Tambahkan repositori MariaDB 10 ke sistem
echo "[mariadb]" | tee /etc/yum.repos.d/MariaDB.repo
echo "name = MariaDB" | tee -a /etc/yum.repos.d/MariaDB.repo
echo "baseurl = http://yum.mariadb.org/10.6/centos7-amd64" | tee -a /etc/yum.repos.d/MariaDB.repo
echo "gpgkey = https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" | tee -a /etc/yum.repos.d/MariaDB.repo
echo "gpgcheck = 1" | tee -a /etc/yum.repos.d/MariaDB.repo
yum install MariaDB-server MariaDB-client -y
systemctl start mariadb
systemctl enable mariadb

[ -f "sets.txt" ] || wget https://github.com/nooufiy/ilamp74/raw/main/sets.txt
[ -f "sets.txt" ] || { exit 1; }
rpas="$(sed -n '1p' sets.txt)*"
mail="$(sed -n '2p' sets.txt)@outlook.com"

# Run mariadb-secure-installation
expect <<EOF
spawn mariadb-secure-installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Switch to unix_socket authentication"
send "Y\r"
expect "Change the root password?"
send "Y\r"
expect "New password:"
send "$rpas\r"
expect "Re-enter new password:"
send "$rpas\r"
expect "Remove anonymous users?"
send "Y\r"
expect "Disallow root login remotely?"
send "n\r"
expect "Remove test database and access to it?"
send "Y\r"
expect "Reload privilege tables now?"
send "Y\r"
expect eof
EOF

# PHP
# ===
# yum-config-manager --enable remi-php74
# yum -y install php php-opcache
# yum install -y php74-php-cli.x86_64 php74-php-fpm.x86_64 php74-php-gd.x86_64 php74-php-geos.x86_64 php74-php-json.x86_64 php74-php-mbstring.x86_64 php74-php-mcrypt.x86_64 php74-php-opcache.x86_64 php74-php-xml.x86_64 php74-php-xmlrpc.x86_64
# php -v

install_php() {
    yum install epel-release yum-utils -y
    yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y

    if [[ "$phpv" == "php74" ]]; then
        yum-config-manager --enable remi-php74
    elif [[ "$phpv" == "php81" ]]; then
        yum-config-manager --enable remi-php81
    else
        echo "Versi PHP tidak valid. Gunakan 7.4 atau 8.1."
        exit 1
    fi

    yum install php-fpm php-common php-mysqlnd php-xml php-gd php-opcache php-mbstring php-json php-cli php-geos php-mcrypt php-xmlrpc -y

    systemctl start php-fpm
    systemctl enable php-fpm
    systemctl status php-fpm
}
install_php

# AASPELL
# =======
# yum -y install php-pspell
# yum install -y aspell-bn aspell-br aspell-ca aspell-cs aspell-cy aspell-da aspell-de aspell-el aspell-en aspell-es aspell-fi aspell-fo aspell-fr aspell-ga aspell-gd aspell-gl aspell-gu aspell-he aspell-hi aspell-hr aspell-id aspell-is aspell-it aspell-la aspell-ml aspell-mr aspell-mt aspell-nl aspell-no aspell-or aspell-pa aspell-pl aspell-pt aspell-ru aspell-sk aspell-sl aspell-sr aspell-sv aspell-ta aspell-te
# aspell dump dicts

yum install -y gcc php-devel php-pear
yum install -y ImageMagick ImageMagick-devel
yes | pecl install imagick
echo "extension=imagick.so" >/etc/php.d/imagick.ini
convert -version
yum -y install libtool httpd-devel

# PA
# ===
yum install -y phpmyadmin
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
wget https://github.com/nooufiy/ilamp74/raw/main/pmin.txt
mv /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin_bak
mv pmin.txt /etc/httpd/conf.d/phpMyAdmin.conf
chcon -u system_u -r object_r -t httpd_config_t /etc/httpd/conf.d/phpMyAdmin.conf

# WP
# ===
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
# wp --info

# FM
# ===
dirFM="_fm"
wget -O "$dpub"/w/"$dirFM".zip https://github.com/nooufiy/"$dirFM"/archive/main.zip && unzip "$dpub"/w/"$dirFM".zip -d "$dpub"/w && rm "$dpub"/w/"$dirFM".zip && mv "$dpub"/w/"$dirFM"-main "$dpub"/w/"$dirFM"
chown -R admin:admin "$dpub"/w/"$dirFM"
mv -f "$dpub"/w/"$dirFM"/getData.php "$dpub"/w/index.php
mv -f "$dpub"/w/"$dirFM"/.htaccess "$dpub"/w

httpaut="RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]"
sed -i "2i $httpaut" "$dpub"/w/.htaccess

# CF
# ===
cd /tmp
#wget https://www.cloudflare.com/static/misc/mod_cloudflare/mod_cloudflare.c
wget https://raw.githubusercontent.com/cloudflare/mod_cloudflare/master/mod_cloudflare.c
apxs -a -i -c mod_cloudflare.c
wget https://github.com/nooufiy/ilamp74/raw/main/mod_cloudflare.so
mv mod_cloudflare.so /usr/lib64/httpd/modules/
chmod 755 /usr/lib64/httpd/modules/mod_cloudflare.so
# echo "LoadModule cloudflare_module /usr/lib64/httpd/modules/mod_cloudflare.so" >> /etc/httpd/conf.d/cloudflare.conf
chcon -t httpd_modules_t /usr/lib64/httpd/modules/mod_cloudflare.so

# LR
# ===
yum -y install logrotate
mv /etc/logrotate.d/httpd /etc/logrotate.d/httpd.bak
#cd /etc/logrotate.d
#wget https://raw.githubusercontent.com/nooufiy/ilamp81/main/httpd
echo "$dpub/l/access_log
$dpub/l/ssl_request_log
$dpub/l/ssl_access_log
$dpub/l/error_log
$dpub/l/ssl_error_log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    dateext
    dateformat -%Y-%m-%d
    postrotate
        /bin/systemctl reload httpd >/dev/null 2>&1 || true
    endscript
}" >/etc/logrotate.d/httpd
logrotate -f /etc/logrotate.d/httpd

sed -i "s|DocumentRoot \"/var/www/html\"|DocumentRoot \"$dpub\/w\"|" /etc/httpd/conf/httpd.conf
sed -i "s|<Directory \"/var/www/html\"|<Directory \"$dpub\/w\"|" /etc/httpd/conf/httpd.conf
sed -i '152s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
sed -i 's/max_execution_time = 30/max_execution_time = 1500/g' /etc/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 300M/g' /etc/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 300M/g' /etc/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/g' /etc/php.ini

# VH
# ===
vhs="manual" #dinamis/manual
if [ "$vhs" == "manual" ]; then
  # Vhost manual
  echo "IncludeOptional conf.s/*.conf" >>/etc/httpd/conf/httpd.conf
  wget https://github.com/nooufiy/ilamp74/raw/main/vh.sh
  mv vh.sh "$ds"
  chmod +x "$vh_sh"
  wget https://github.com/nooufiy/ilamp74/raw/main/setdom.sh
  mv setdom.sh "$ds"
  chmod +x "$ds/setdom.sh"
  wget https://github.com/nooufiy/ilamp74/raw/main/upd.sh
  mv upd.sh "$ds"
  chmod +x "$ds/upd.sh"

  confsdir="/etc/httpd/conf.s"
  confsfil="$confsdir/sites.conf"

  cat <<EOF | sudo tee -a "$ds/cnf.txt" >/dev/null
email=$mail
sites_conf_dir=$confsdir
sites_conf=$confsfil
home_dir=$dpub/w
home_dt=$dpub/d
home_lg=$dpub/l
processed_file=$ds/processed_domains.txt
sslbekup=$ds/ssl
pw=$rpas
rundir=$ds/r
EOF

  if [[ ! -d "/etc/httpd/conf.s" ]]; then
    mkdir -p "/etc/httpd/conf.s"
  fi
  if [[ ! -f "$ds/processed_domains.txt" ]]; then
    >"$ds/processed_domains.txt"
  fi
  script_path="$ds/vh.sh"
  service_file="/etc/systemd/system/mysts.service"

  cat <<EOF >"$service_file"
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

else

  # Vhost dinamis
  sites_dir="$dpub/w"
  apache_conf="/etc/httpd/conf/httpd.conf"
  # Mengecek apakah modul vhost_alias sudah diaktifkan
  if ! grep -q "LoadModule vhost_alias_module" "$apache_conf"; then
    echo "LoadModule vhost_alias_module modules/mod_vhost_alias.so" | sudo tee -a "$apache_conf" >/dev/null
  fi
  # Mengaktifkan pengaturan VirtualDocumentRoot
  if ! grep -q "VirtualDocumentRoot" "$apache_conf"; then
    echo "VirtualDocumentRoot $sites_dir/%0" | sudo tee -a "$apache_conf" >/dev/null
  fi

  # Ssl

  wget https://github.com/nooufiy/ilamp74/raw/main/ssl.sh
  mv ssl.sh "$ds"

  sed -i "3i email=\"$mail\"" "$ssl_sh"
  sed -i "4i home_dir=\"$dpub/w\"" "$ssl_sh"
  chmod +x "$ssl_sh"

  script_path="$ds/ssl.sh"
  service_file="/etc/systemd/system/myssl.service"

  cat <<EOF >"$service_file"
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

# SSH2
# =====
yum install libssh2 libssh2-devel make -y
# pecl install ssh2
yum install php-ssh2 -y

# pecl install ssh2-1.3.1
# echo "extension=ssh2.so" | sudo tee /etc/php.d/ssh2.ini
# echo "extension=ssh2.so" >> /etc/php.d/ssh2.ini
echo "extension=ssh2.so" | tee /etc/php.d/20-ssh2.ini

rm -rf /root/sets.txt
sed -i "97i ServerName localhost" /etc/httpd/conf/httpd.conf

# PERMISSION
# ===========
chown -R apache:apache "$dpub"
chcon -R system_u:object_r:httpd_sys_content_t "$dpub"/{w,l,d}
chcon -R -u system_u -r object_r -t httpd_sys_rw_content_t "$dpub"/{w,l,d}
# semanage boolean --modify --on httpd_can_network_connect
# /usr/sbin/setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_connect 1
systemctl enable httpd.service
systemctl restart httpd.service

sed -i "4i alias ceklog='sudo tail -f /var/log/httpd/error_log'" ~/.bashrc
source ~/.bashrc

# SELINUX
# ========
sestatus | grep -q 'disabled' && sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config && sudo setenforce 1

# IONCUBE
# =======
phpVersion=$(echo "$phpv" | sed -r 's/php([0-9])([0-9]+)/\1.\2/')

wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xzf ioncube_loaders_lin_x86-64.tar.gz
sudo mv ioncube/ioncube_loader_lin_"$phpVersion".so /usr/lib64/php/modules/

# Buat file konfigurasi IonCube Loader
sudo tee /etc/php.d/00-ioncube.ini >/dev/null <<EOF
zend_extension = /usr/lib64/php/modules/ioncube_loader_lin_$phpVersion.so
EOF

chown -R apache:apache /usr/lib64/php/modules/ioncube_loader_lin_"$phpVersion".so
chcon -R -u system_u -r object_r -t httpd_sys_rw_content_t /usr/lib64/php/modules/ioncube_loader_lin_"$phpVersion".so
sudo chcon -t textrel_shlib_t /usr/lib64/php/modules/ioncube_loader_lin_"$phpVersion".so

# NODEJS
# =======
# curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
yum install nodejs -y

# FIREWALLD
# ==========
yum -y install firewalld
sed -i 's/^AllowZoneDrifting=.*/AllowZoneDrifting=no/' /etc/firewalld/firewalld.conf
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd --permanent --zone=public --add-port=25/tcp
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --permanent --zone=public --add-service=mysql
firewall-cmd --permanent --zone=public --add-service=smtp
firewall-cmd --permanent --add-port=9000/tcp
firewall-cmd --reload
# firewall-cmd --permanent --add-rich-rule='rule service name=ssh limit value="3/m" drop'



# SSH
# ====
sed -i "s/#Port 22/Port $aport/" /etc/ssh/sshd_config
firewall-cmd --permanent --zone=public --add-port="$aport"/tcp
firewall-cmd --zone=public --add-port="$aport"/tcp
firewall-cmd --reload
# firewall-cmd --zone=public --list-ports

yum install policycoreutils -y
yum whatprovides semanage
yum provides *bin/semanage
yum -y install policycoreutils-python
semanage port -a -t ssh_port_t -p tcp "$aport"
systemctl restart sshd
systemctl restart firewalld


# FINISH
# =======
curl -X POST -d "data=$trimmed" "$url/srv/"

echo "sv71=$url" >>"$ds/cnf.txt"
sed -i '/^$/d' "$ds/cnf.txt"

sed -i "s/dbmin/$rurl/g" /etc/httpd/conf.d/phpMyAdmin.conf
mv "$dpub/w/$dirFM" "$dpub/w/_$rurl"

cat <<EOF | sudo tee -a /etc/httpd/conf.s/sites.conf >/dev/null
<VirtualHost *:80>
    DocumentRoot $dpub/w
    ServerName $ip
    RewriteEngine on
    ErrorLog $home_lg/"$ip"_error.log
    CustomLog $home_lg/"$ip"_access.log combined
</VirtualHost>
EOF

cat <<EOF | sudo tee -a /etc/httpd/conf/httpd.conf >/dev/null
<FilesMatch \.php$>
	SetHandler "proxy:fcgi://127.0.0.1:9000"
</FilesMatch>
EOF

service httpd restart
rm -rf /root/u.txt

# SERVICE STATUS
# ==============
service httpd status
service mariadb status
service firewalld status
service sshd status
service mysts status

echo ""
echo "== [DONE] =="
echo ""

end_time=$(date +%s)
execution_time=$((end_time - start_time))

echo "in $execution_time seconds"
echo "done in $execution_time seconds" >/root/done.txt
