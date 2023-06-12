#!/bin/bash



sites_conf_dir="/etc/httpd/conf.s"
sites_conf="$sites_conf_dir/sites.conf"
processed_file="/rs/processed_domains.txt"

# Fungsi untuk menulis ke file sites.conf
write_to_sites_conf() {
  echo "<VirtualHost *:80>" >> "$sites_conf"
  echo "DocumentRoot $home_dir/$1" >> "$sites_conf"
  echo "ServerName $1" >> "$sites_conf"

  if [[ $2 == "domain" ]]; then
    echo "ServerAlias www.$1" >> "$sites_conf"
  fi

  echo "</VirtualHost>" >> "$sites_conf"

  echo "File $sites_conf updated."
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
  domain_list=($(find "$home_dir" -maxdepth 1 -type d -printf "%f\n" | grep -v "w"))

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

        # Menandai domain sebagai telah diproses
        echo "$domain" >> "$processed_file"

        # Menjalankan certbot untuk mendapatkan sertifikat SSL
        certbot --apache -d "$domain" --email "$email" --agree-tos -n
      fi
    done
  fi

  sleep 20
done
