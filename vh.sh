#!/bin/bash

sites_conf_dir="/etc/httpd/conf.s"
sites_conf="$sites_conf_dir/sites.conf"

write_to_sites_conf() {
    echo "<VirtualHost *:80>" >> "$sites_conf"
    echo "DocumentRoot $home_dir/$1" >> "$sites_conf"
    echo "ServerName $1" >> "$sites_conf"

    if [[ $2 == "domain" ]]; then
        echo "ServerAlias www.$1" >> "$sites_conf"
    fi

    echo "</VirtualHost>" >> "$sites_conf"
}

if [[ ! -d "$sites_conf_dir" ]]; then
  mkdir -p "$sites_conf_dir"
fi

if [[ ! -f "$processed_file" ]]; then
  touch "$processed_file"
fi

htawp="# BEGIN WordPress\n\n\
RewriteEngine On\n\
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]\n\
RewriteBase /\n\
RewriteRule ^index\.php$ - [L]\n\
RewriteCond %{REQUEST_FILENAME} !-f\n\
RewriteCond %{REQUEST_FILENAME} !-d\n\
RewriteRule . /index.php [L]\n\n\
# END WordPress\n"

while true; do
  
  if [[ -f "$home_dt/domains.txt" && -s "$home_dt/domains.txt" ]]; then
    # domain_list=($(less "$home_dt/domains.txt"))
    domain_list=($(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$home_dt/domains.txt"))

    # Memeriksa apakah ada perubahan pada daftar domain/subdomain
    if [[ ! -z "${domain_list[*]}" ]]; then
        new_domains=()

        # Loop untuk setiap domain/subdomain
        for domain in "${domain_list[@]}"; do
            # if ! grep -q "$domain" "$processed_file"; then
            if ! grep -q -E "\b$domain\b" "$processed_file"; then
                new_domains+=("$domain") # Menambahkan domain yang belum dieksekusi ke dalam array new_domains
            fi
        done

        if [[ ! -z "${new_domains[*]}" ]]; then
            # echo "Domain baru yang akan dieksekusi:"
            for newdomain in "${new_domains[@]}"; do
                # Menulis konfigurasi virtual host ke sites.conf
                dot_count=$(grep -o "\." <<< "$newdomain" | wc -l)
                if [[ dot_count -eq 1 ]]; then
                write_to_sites_conf "$newdomain" "domain"
                elif [[ dot_count -eq 2 ]]; then
                write_to_sites_conf "$newdomain" "subdomain"
                fi

                mkdir "$home_dir/$newdomain"
                timestamp=$(date +%s)
                short=$(echo "$newdomain" | sed 's/\.//g' | cut -c 1-5)
                rand_chars=$(head /dev/urandom | tr -dc 'a-z' | fold -w 3 | head -n 1)
                dbuser="${short}_usr_${rand_chars}"
                dbname="${short}_nam_${rand_chars}"
                dbpass="${short}_pas_${timestamp}"

                pw=""

                if ! mysql -u root -p"$pw" -e "SELECT COUNT(*) FROM mysql.user WHERE user = '$dbuser';" | grep -q '1'; then
                  mysql -u root -p"$pw" -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
                fi

                if mysql -u root -p"$pw" -e "USE $dbname;" ; then
                    mysql -u root -p"$pw" -e "DROP DATABASE $dbname;"
                fi

                mysql -u root -p"$pw" -e "CREATE DATABASE IF NOT EXISTS $dbname;"
                mysql -u root -p"$pw" -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
                mysql -u root -p"$pw" -e "FLUSH PRIVILEGES;"

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

                echo -e "$htawp" > "$home_dir/$newdomain/.htaccess"

                wp core install --url="http://$newdomain/" --title="$newdomain" --admin_user="admin" --admin_password=rahasi4a911* --admin_email="$email" --allow-root
                wp option update blogdescription "" --allow-root
                wp rewrite structure '/%postname%/' --hard --allow-root

                chown -R apache:apache "$home_dir/$newdomain"
                # chmod -R 755 "$home_dir/$newdomain"
                chcon -R system_u:object_r:httpd_sys_content_t "$home_dir/$newdomain"
                chcon -R -u system_u -r object_r -t httpd_sys_rw_content_t "$home_dir/$newdomain"

                if certbot certificates | grep -q "Expiry Date"; then
                    echo "Sertifikat ada."
                else
                    echo "Sertifikat tidak ada atau sudah expired."
                    # certbot --apache -d "$newdomain" --email "$email" --agree-tos -n

                    # Hitung jumlah titik dalam string
                    num_dots=$(echo "$newdomain" | tr -cd '.' | wc -c)
                    # Cek apakah jumlah titik adalah satu
                    if [ "$num_dots" -eq 1 ]; then
                        # echo "Jumlah titik adalah satu."
                        certbot --apache -d "$newdomain" -d "www.$newdomain" --email "$email" --agree-tos -n
                    else
                        certbot --apache -d "$newdomain" --email "$email" --agree-tos -n
                    fi
                fi

                # echo "$newdomain,$dbuser,$dbname,$dbpass" >> "$processed_file"
                cleaned_newdomain=$(echo "$newdomain" | tr -d '\r')
				echo "$cleaned_newdomain,$dbuser,$dbname,$dbpass" >> "$processed_file"
                service httpd graceful
            done
            
            ssl_dir="/etc/letsencrypt"
            backup_file="ssl_backup_$(date +%Y%m%d).tar.gz"
            tar -czvf "$sslbekup/$backup_file" "$ssl_dir"

            # Hapus backup lama (lebih dari 3 hari)
            old_backups=$(find "$sslbekup" -name "ssl_backup_*.tar.gz" -type f -mtime +3)
            if [[ -n $old_backups ]]; then
                rm -f $old_backups
            fi
        fi
    fi
  fi
  sleep 20
done
