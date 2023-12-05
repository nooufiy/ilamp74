#!/bin/bash

sed -i 's/\r//g' /rs/cnf.txt
source "/rs/cnf.txt"

while true; do

    if [[ -f "$home_dt/domains.txt" && -s "$home_dt/domains.txt" ]]; then
        # domain_list=($(less "$home_dt/domains.txt"))
        domain_list=($(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$home_dt/domains.txt"))

        # Memeriksa apakah ada perubahan pada daftar domain/subdomain
        if [[ ! -z "${domain_list[*]}" ]]; then
            new_domains=()

            # Loop untuk setiap domain/subdomain
            # for domain in "${domain_list[@]}"; do
            for dtdom in "${domain_list[@]}"; do
                pieces=(${dtdom//_/ })
                domain="${pieces[0]}"
                platf="${pieces[1]}"
                ip="${pieces[2]}"
                enkode="${pieces[3]}"
                usrid="${pieces[4]}"

                # if ! grep -q "$domain" "$processed_file"; then
                if ! grep -q -E "\b$domain\b" "$processed_file"; then
                    # new_domains+=("$domain") # Menambahkan domain yang belum dieksekusi ke dalam array new_domains
                    # new_domains+=("${domain}_${platf}_${enkode}")
                    new_domains+=("${dtdom}")

                fi
            done

            if [[ ! -z "${new_domains[*]}" ]]; then
                # echo "Domain baru yang akan dieksekusi:"
                # for newdomain in "${new_domains[@]}"; do
                for newdtdom in "${new_domains[@]}"; do
                    ndtdom=(${newdtdom//_/ })
                    newdomain="${ndtdom[0]}"
                    # platform="${ndtdom[1]}"
                    # enkod="${ndtdom[2]}"

                    # >"$rundir/rundom.txt"
                    if [[ ! -d "$rundir/active" ]]; then
                        mkdir -p "$rundir/active"
                    fi

                    # Cek keberadaan file domain1.txt
                    if [ ! -f "$rundir/active/$newdomain.txt" ]; then
                        screen -dmS "$newdomain" sh /rs/setdom.sh "$newdtdom"
                    fi
                done

            fi
        fi
    fi

    # BEKAP SSL
    if [ -d "$rundir/active" ] && [ -z "$(ls -A "$rundir/active")" ]; then
        echo "Proses A: Direktori $active_dir ada dan kosong."
        ssl_dir="/etc/letsencrypt"
        backup_file="ssl_backup_$(date +%Y%m%d).tar.gz"
        tar -czvf "$sslbekup/$backup_file" "$ssl_dir"

        old_backups=$(find "$sslbekup" -name "ssl_backup_*.tar.gz" -type f -mtime +3) # Hapus backup lama (lebih dari 3 hari)
        if [[ -n $old_backups ]]; then
            rm -f $old_backups
        fi

        rm -rf "$rundir/active"
    fi

    sleep 20
done
