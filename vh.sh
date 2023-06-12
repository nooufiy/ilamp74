#!/bin/bash
# Path ke direktori /home/w dan sites.conf


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

  echo "File $sites_conf updated."
}

# Memeriksa apakah direktori /etc/httpd/conf.d ada
if [[ ! -d "$sites_conf_dir" ]]; then
#   echo "Direktori $sites_conf_dir tidak ditemukan. Membuat direktori..."
  mkdir -p "$sites_conf_dir"
fi

while true; do

# Mendapatkan daftar nama domain dan subdomain dari direktori /home/w
domain_list=$(find "$home_dir" -mindepth 1 -maxdepth 1 -type d -printf "%f\n")

# Memeriksa apakah ada perubahan pada daftar domain/subdomain
if [[ ! -z $domain_list ]]; then
  # Memeriksa apakah file sites.conf ada
  if [[ -f "$sites_conf" ]]; then
    # Memeriksa apakah ada perubahan pada file sites.conf
    sites_conf_hash=$(md5sum "$sites_conf" | awk '{print $1}')
    domain_list_hash=$(echo "$domain_list" | md5sum | awk '{print $1}')
    if [[ $sites_conf_hash != $domain_list_hash ]]; then
      # Menulis ke file sites.conf
      > "$sites_conf" # Mengosongkan file sites.conf
      while IFS= read -r domain; do
        dot_count=$(grep -o "\." <<< "$domain" | wc -l)
        if [[ dot_count -eq 1 ]]; then
          write_to_sites_conf "$domain" "domain"
        elif [[ dot_count -eq 2 ]]; then
          write_to_sites_conf "$domain" "subdomain"
        fi
      done <<< "$domain_list"
    else
    #   echo "no update $home_dir."
      echo ""
    fi
  else
    # Menulis ke file sites.conf karena file tidak ditemukan
    > "$sites_conf" # Mengosongkan file sites.conf
    while IFS= read -r domain; do
      dot_count=$(grep -o "\." <<< "$domain" | wc -l)
      if [[ dot_count -eq 1 ]]; then
        write_to_sites_conf "$domain" "domain"
      elif [[ dot_count -eq 2 ]]; then
        write_to_sites_conf "$domain" "subdomain"
      fi
    done <<< "$domain_list"
  fi
  
  certbot --apache -d "$domain" --email "$email" --agree-tos -n

else
#   echo "not found new domain $home_dir."
  echo ""
fi

sleep 20
done
