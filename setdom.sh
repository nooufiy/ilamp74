#!/bin/bash

sed -i 's/\r//g' /rs/cnf.txt
source "/rs/cnf.txt"
newdtdom="$1"
ndtdom=(${newdtdom//_/ })
newdomain="${ndtdom[0]}"
platform="${ndtdom[1]}"
ip="${ndtdom[2]}"
enkod="${ndtdom[3]}"
userid="${ndtdom[4]}"
status="${ndtdom[5]}"

> "$rundir/active/$newdomain.txt"

# Menulis konfigurasi virtual host ke sites.conf
dot_count=$(grep -o "\." <<< "$newdomain" | wc -l)
if [[ dot_count -eq 1 ]]; then
	#write_to_sites_conf "$newdomain" "domain"
	cat <<EOF | sudo tee -a "$sites_conf" >/dev/null
<VirtualHost *:80>
    DocumentRoot $home_dir/$newdomain
    ServerName $newdomain
	ServerAlias www.$newdomain
    RewriteEngine on
</VirtualHost>
EOF
elif [[ dot_count -eq 2 ]]; then
	#write_to_sites_conf "$newdomain" "subdomain"
	cat <<EOF | sudo tee -a "$sites_conf" >/dev/null
<VirtualHost *:80>
    DocumentRoot $home_dir/$newdomain
    ServerName $newdomain
    RewriteEngine on
</VirtualHost>
EOF
fi

mkdir "$home_dir/$newdomain"

timestamp=$(date +%s)
short=$(echo "$newdomain" | sed 's/\.//g' | cut -c 1-5)
rand_chars=$(head /dev/urandom | tr -dc 'a-z' | fold -w 3 | head -n 1)
dbuser="${short}_usr_${rand_chars}"
dbname="${short}_nam_${rand_chars}"
dbpass="${short}_pas_${timestamp}"


if ! mysql -u root -p"$pw" -e "SELECT COUNT(*) FROM mysql.user WHERE user = '$dbuser';" | grep -q '1'; then
	mysql -u root -p"$pw" -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
fi

if mysql -u root -p"$pw" -e "USE $dbname;" ; then
	mysql -u root -p"$pw" -e "DROP DATABASE $dbname;"
fi

mysql -u root -p"$pw" -e "CREATE DATABASE IF NOT EXISTS $dbname;"
mysql -u root -p"$pw" -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
mysql -u root -p"$pw" -e "FLUSH PRIVILEGES;"

# BUILD WP
if [ "$platform" = "wordpress" ]; then

	wget -P "$home_dir/$newdomain" https://wordpress.org/latest.tar.gz
	tar -zxvf "$home_dir/$newdomain/latest.tar.gz" -C "$home_dir/$newdomain" --strip-components=1
	cp "$home_dir/$newdomain/wp-config-sample.php" "$home_dir/$newdomain/wp-config.php"
	sed -i "s/database_name_here/$dbname/g" "$home_dir/$newdomain/wp-config.php"
	sed -i "s/username_here/$dbuser/g" "$home_dir/$newdomain/wp-config.php"
	sed -i "s/password_here/$dbpass/g" "$home_dir/$newdomain/wp-config.php"

perl -i -pe'
BEGIN {
	@chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
	push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
	sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
}
s/put your unique phrase here/salt()/ge
' "$home_dir/$newdomain/wp-config.php"

	[ ! -d "$home_dir/$newdomain/wp-content/uploads" ] && mkdir "$home_dir/$newdomain/wp-content/uploads"

	cd "$home_dir/$newdomain"

# echo -e "$htawp" > "$home_dir/$newdomain/.htaccess"
cat <<EOF > "$home_dir/$newdomain/.htaccess"
# BEGIN WordPress

<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    RewriteBase /
    RewriteRule ^index\.php$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.php [L]
</IfModule>

# END WordPress
EOF

wp core install --url="http://$newdomain/" --title="$newdomain" --admin_user="admin" --admin_password=rahasi4a911* --admin_email="$email" --allow-root
wp option update blogdescription "" --allow-root
wp rewrite structure '/%postname%/' --hard --allow-root

# BUILD NATIVE
else
	urlFileZip=$(echo "$enkod" | base64 -d)
	# Mengunduh file zip dari URL
	if wget -q "$urlFileZip"; then
		unzip -o temp.zip -d "$home_dir/$newdomain" # Mengekstrak isi file zip ke direktori tujuan
		rm temp.zip
	else
		echo "fail download."
	fi

fi

chown -R apache:apache "$home_dir/$newdomain"
# chmod -R 755 "$home_dir/$newdomain"
chcon -R system_u:object_r:httpd_sys_content_t "$home_dir/$newdomain"
chcon -R -u system_u -r object_r -t httpd_sys_rw_content_t "$home_dir/$newdomain"

if certbot certificates | grep -q "Expiry Date"; then
	echo "Sertifikat ada."
else
	echo "Sertifikat tidak ada atau sudah expired."

	# Hitung jumlah titik dalam string
	num_dots=$(echo "$newdomain" | tr -cd '.' | wc -c)
	# Cek apakah jumlah titik adalah satu
	if [ "$num_dots" -eq 1 ]; then
		certbot --apache -d "$newdomain" -d "www.$newdomain" --email "$email" --agree-tos -n
	else
		certbot --apache -d "$newdomain" --email "$email" --agree-tos -n
	fi
fi

# echo "$newdomain,$dbuser,$dbname,$dbpass" >> "$processed_file"
cleaned_newdomain=$(echo "$newdomain" | tr -d '\r')
echo "$cleaned_newdomain,$dbuser,$dbname,$dbpass" >> "$processed_file"
dondom=${newdtdom//_setup/_done}
curl -X POST -d "data=$dondom" "$sv71/dom.php"
sed -i "s/$newdtdom/$dondom/g" "$home_dt/domains.txt"
service httpd graceful

rm -rf "$rundir/active/$newdomain.txt"
# sed -i "/$newdomain/d" "$rundir/rundom.txt"
