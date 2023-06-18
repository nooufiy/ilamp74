#!/bin/bash

sites_conf_dir="/etc/httpd/conf.s"
sites_conf="$sites_conf_dir/sites.conf"

# Fungsi untuk menulis ke file sites.conf
write_to_sites_conf() {
    echo "<VirtualHost *:80>" >> "$sites_conf"
    echo "DocumentRoot $home_dir/$1" >> "$sites_conf"
    echo "ServerName $1" >> "$sites_conf"

    if [[ $2 == "domain" ]]; then
        echo "ServerAlias www.$1" >> "$sites_conf"
    fi

    echo "</VirtualHost>" >> "$sites_conf"
    # echo "File $sites_conf updated."
}

# Memeriksa apakah direktori /etc/httpd/conf.d ada
if [[ ! -d "$sites_conf_dir" ]]; then
  mkdir -p "$sites_conf_dir"
fi

# Memeriksa apakah file processed_domains.txt ada
if [[ ! -f "$processed_file" ]]; then
  touch "$processed_file"
fi

while true; do
  # Mendapatkan daftar domain dan subdomain dari direktori /sites/w
  
  if [[ -f "$home_dir/domains.txt" && -s "$home_dir/domains.txt" ]]; then
    domain_list=($(less "$home_dir/domains.txt"))

    # Memeriksa apakah ada perubahan pada daftar domain/subdomain
    if [[ ! -z "${domain_list[*]}" ]]; then
        # Loop untuk setiap domain/subdomain
        for domain in "${domain_list[@]}"; do
        # Memeriksa apakah domain belum diproses sebelumnya
        if ! grep -q "$domain" "$processed_file"; then
            # Menulis konfigurasi virtual host ke sites.conf
            dot_count=$(grep -o "\." <<< "$domain" | wc -l)
            if [[ dot_count -eq 1 ]]; then
            write_to_sites_conf "$domain" "domain"
            elif [[ dot_count -eq 2 ]]; then
            write_to_sites_conf "$domain" "subdomain"
            fi

            # gaewp
            mkdir "$home_dir/$domain"

            timestamp=$(date +%s)
            # short=${domain:0:5}
            short=$(echo "$domain" | sed 's/\.//g' | cut -c 1-5)
            rand_chars=$(head /dev/urandom | tr -dc 'a-z' | fold -w 3 | head -n 1)
            dbuser="${short}_usr_${rand_chars}"
            dbname="${short}_nam_${rand_chars}"

            dbpass="${short}_pas_${timestamp}"

            pw=""

            # mysql -u root -p"$pw" -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"

            if ! mysql -u root -p"$pw" -e "SELECT COUNT(*) FROM mysql.user WHERE user = '$dbuser';" | grep -q '1'; then
              mysql -u root -p"$pw" -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
            fi

            if mysql -u root -p"$pw" -e "USE $dbname;" ; then
                mysql -u root -p"$pw" -e "DROP DATABASE $dbname;"
            fi

            # echo '--Create Database--'$'\r'$'\r'
            # mysql -u root -p"$pw" -e "CREATE DATABASE $dbname;"
            # mysql -u root -p"$pw" -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
            mysql -u root -p"$pw" -e "CREATE DATABASE IF NOT EXISTS $dbname;"
            mysql -u root -p"$pw" -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
            mysql -u root -p"$pw" -e "FLUSH PRIVILEGES;"

            wget -P "$home_dir/$domain" https://wordpress.org/latest.tar.gz
            tar -zxvf "$home_dir/$domain/latest.tar.gz" -C "$home_dir/$domain" --strip-components=1
            # tar -zxvf "$home_dir/$domain/latest.tar.gz" --directory "$home_dir/$domain"
            # mv "$home_dir/$domain/wordpress/*" "$home_dir/$domain"
            cp "$home_dir/$domain/wp-config-sample.php" "$home_dir/$domain/wp-config.php"
            sed -i "s/database_name_here/$dbname/g" "$home_dir/$domain/wp-config.php"
            sed -i "s/username_here/$dbuser/g" "$home_dir/$domain/wp-config.php"
            sed -i "s/password_here/$dbpass/g" "$home_dir/$domain/wp-config.php"

            #set WP salts
            perl -i -pe'
            BEGIN {
                @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
                push @chars, split //, "!@#$%^&*()-_ []{}<>~\`+=,.;:/?|";
                sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
            }
            s/put your unique phrase here/salt()/ge
            ' "$home_dir/$domain/wp-config.php"

            #create uploads folder and set permissions
            [ ! -d "$home_dir/$domain/wp-content/uploads" ] && mkdir "$home_dir/$domain/wp-content/uploads"

            # htawp="# BEGIN WordPress\n\n\
            # RewriteEngine On\n\
            # RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]\n\
            # RewriteBase /\n\
            # RewriteRule ^index\.php$ - [L]\n\
            # RewriteCond %{REQUEST_FILENAME} !-f\n\
            # RewriteCond %{REQUEST_FILENAME} !-d\n\
            # RewriteRule . /index.php [L]\n\n\
            # # END WordPress\n"

            # echo -e "$htawp" > "$home_dir/$domain/.htaccess"

            chown -R apache:apache "$home_dir/$domain"

            cd "$home_dir/$domain"
            wp core install --url="http://$domain/" --title="$domain" --admin_user="admin" --admin_password=rahasi4a911* --admin_email="$email" --allow-root
            wp option update blogdescription "" --allow-root
            wp rewrite structure '/%postname%/' --hard --allow-root

            chown -R apache:apache "$home_dir/$domain"
            chmod -R 755 "$home_dir/$domain"
            chcon -R system_u:object_r:httpd_sys_content_t "$home_dir/$domain"

            if certbot certificates | grep -q "Expiry Date"; then
                echo "Sertifikat ada."
            else
                echo "Sertifikat tidak ada atau sudah expired."
                certbot --apache -d "$domain" --email "$email" --agree-tos -n
            fi

            # echo "$domain" >> "$processed_file"
            echo "$domain,$dbuser,$dbname,$dbpass" >> "$processed_file"
        fi
        done
    fi
  fi

  service httpd graceful

  ssl_dir="/etc/letsencrypt"
  backup_file="ssl_backup_$(date +%Y%m%d).tar.gz"
  tar -czvf "$sslbekup/$backup_file" "$ssl_dir"

  # Hapus backup lama (lebih dari 3 hari)
  old_backups=$(find "$sslbekup" -name "ssl_backup_*.tar.gz" -type f -mtime +3)
  if [[ -n $old_backups ]]; then
      rm -f $old_backups
  fi

  sleep 20
done
