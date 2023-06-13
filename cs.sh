#!/bin/bash

# Mendapatkan path file domain.txt

file_path="domains.txt"
# Memeriksa apakah file domain.txt ada
if [ ! -f "$file_path" ]; then
  echo " => File domains.txt not found."
  exit 1
fi

# Loop untuk membaca file domain.txt dan membuat direktori
while IFS= read -r direktori; do
    # Membuat direktori
    mkdir "$home_dir/$direktori"

    # Membuat file index.php di dalam direktori
    touch "$home_dir/$direktori/index.php"

    # Mengubah pemilik file index.php menjadi apache
    chown -R apache:apache "$home_dir/$direktori"

    # Menampilkan pesan berhasil
    if [ $? -eq 0 ]; then
        echo " => success dir $direktori."
    else
        echo " => faild dir $direktori."
    fi

done < "$file_path"
echo ""
echo "Done."
echo ""
