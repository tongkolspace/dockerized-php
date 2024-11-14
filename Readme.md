# Mukadimah

Docker stack production ready untuk aplikasi PHP dengan template Ubuntu dan Alpine

| Images         | Services                                      |                        |
|----------------|-----------------------------------------------|------------------------|
| WordPress      | Nginx                                         | Virtubox Nginx EE      |
|                | PHP-FPM                                       | PHP 8.2                |
|                | Background-Job                                |                        |
|                | Admin Tools                                   | Phpmyadmin, Redis Commander, Nginx VTS |
| Proxy          | Traefik                                       | Reverse Proxy          |
|                | Admin Tools                                   | Traefik Dashboard      |

# Environment

Terdapat beberapa template yang dapat dikombinasikan untuk mensimulasikan environment development dan production

| Template | file compose | keterangan |
|----------|--------------|------------|
| dev-local | compose-dev-local.yml | Environment pengembangan |
| dev-proxy | compose-dev-proxy.yml | Reverse Proxy |
| dev-tongkolspace | compose-dev-tongkolspace.yml | Simulasi deploy pada server dev |
| dev-container | compose-dev-container.yml | Deploy dengan container |


# Petunjuk Penggunaan
Tambahkan host berikut
```
127.0.0.1 wordpress.local proxy.dev.local
```

## Menjalankan `env` `dev-local`
```
git clone git@github.com:tongkolspace/dockerized-php.git dockerized-php && cd dockerized-php && rm .git -rf
sed -i '/^wordpress*/d' .gitignore
git init
git add ./docker/.env*-sample 
bash wrapper.sh copy_env .env-dev-local-sample .env-dev-local
bash init.sh setup_htaccess
bash init.sh download_wordpress
bash wrapper.sh dev-local up
bash init.sh install_wordpress
```

| Sevice  | URL | Catatan |
|------------|---------|---------|
| WordPress | http://wordpress.local |
| Admin | http://wordpress.local:57710 |

## Menjalankan tanpa docker

Copy `wordpress/.env-wp-sample` -> `.env-wp`, sesuaikan isinya dari `docker/.env-dev-local`
Jika dalam proyek tidak ada `wordpress/.env-wp-sample` gunakan `docker/.env-dev-local` sebagai base


## Menjalankan `env` `dev-tongkolspace`

Untuk menjalankan `dev-tongkolspace` pastikan `dev-local` sudah berjalan lancar

```
bash wrapper.sh dev-local down

# Ganti password pada file .env-dev-local dan .env-dev-tongkolspace
bash wrapper.sh copy_env .env-dev-tongkolspace-sample .env-dev-tongkolspace
bash wrapper.sh copy_env .env-dev-proxy-sample .env-dev-proxy

bash wrapper.sh dev-local dev-tongkolspace dev-proxy up
```
| Sevice  | URL |
|------------|---------|
| WordPress | https://wordpress.local |
| Admin | https://wordpress.local:57710 |
| Admin Traefik | https://proxy.dev.local:57710 |

## Menjalankan `env` `dev-container`

Merupakan environment untuk testing container.
Menggunakan images dari private registry. 
Sebelum menggunakan environment ini, images harus di push ke private registry dahulu 

```
bash push-images.sh 
bash wrapper.sh copy_env .env-dev-container-sample .env-dev-container
bash wrapper.sh dev-local dev-container dev-proxy up
```

Pada konfigurasi ini mounting volumes hanya digunakan untuk persistance data seperti misalnya WordPress uploads folder

# Ownership file

Ownership file pada docker  perlu  diperhatikan dengan seksama. Volume yang di-mount pada docker container akan memiliki GUID dan UID yang sama dengan GUID dan UID pada host machine.

Untuk mempermudah development semua file yang digunakan untuk pengembangan web menggunakan UID dan GUID 1000. Semua service pada Apps juga menggunakan UID 1000. Pada container user UID 1000 ini adalah user `app`

Cek UID pada mesin development sebelum mulai bekerja :

```
# Host (ganti dengan user anda)
$id kasatka
uid=1000(kasatka) gid=1000(kasatka) groups=1000(kasatka)
```

# Interakasi dengan wp-cli

Dalam pengembangan WordPress kita seringkali membutuhkan `wp-cli` untuk melakukan berbagai task. 
Pada template docker ini kita dapat masuk ke dalam container dengan perintah `wrapper.sh dev-local exec wordpress bash`
Kita akan masuk ke container sebagai user `app` dan bisa memanggil perintah seperi `wp-cli core update`

Jika membutuhkan node js atau tools lakukan modifikasi pada `Dockerfile` dan tambahkan tools yang dibutuhkan, kemudian build ulang images.
Contoh modifikasi

```
# Install necessary packages and PHP
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:ondrej/php && \
    add-apt-repository ppa:wordops/nginx-wo -uy && \
    # Tambahkan repositori Node.js
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ... omitted
    # Instal Node.js dan npm
    nodejs && \
    # Instal pnpm
    npm install -g pnpm && \
    apt-get autoremove -y && \
    apt-get purge -y --auto-remove && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

# Service

Terdapat service `nginx`, `php-fpm` dan `background-job` yang berjalan pada container. Service berjalan melalui `docker/app/entrypoint.sh`. Service yang berjalan dapat diaktifkan menggunakan environment `ROLE_$NAMASERVICE`.

| Service    | Penjelasan                    | Role            |
|------------|-------------------------------|-----------------|
| nginx      | Web Server                    | ROLE_NGINX      |
| php-fpm    | PHP Interpreter               | ROLE_PHP_FPM    |
| background | Cronjob atau background job   | ROLE_BACKGROUND |


# Wrapper.sh

Merupakan sebuah _tools_ untuk mempermudah interaksi dengan `docker compose`. 

Perintah dasar : `wrapper.sh {nama-env}` 

Command diatas akan memanggil : `docker compose -f docker/docker-compose-nama-env.yml -e docker/.env-nama-env`

```
./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [up|down|logs|restart|exec]
./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-console]
./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-dump]
./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-import] [db-name] [import-file]

# docker-compose up
./wrapper.sh dev-local up 
./wrapper.sh dev-local up php-fpm nginx redis


# Menjalankan beberapa environment
./wrapper.sh dev-local dev-tongkolspace dev-proxy up 

# masuk ke container db
./wrapper.sh exec dev-local db bash

# Masuk ke container wordpress
./wrapper.sh exec dev-local wordpress bash

# masuk ke console mysql
# docker compose $compose_file exec db mariadb -u root -p$MYSQL_ROOT_PASSWORD
./wrapper.sh exec dev-local mysql-console

# dump db 
# docker compose $compose_file exec -T db mariadb-dump -u root -p$MYSQL_ROOT_PASSWORD $2 > ../$2.sql
./wrapper.sh exec dev-local  mysql-dump [nama-db] 

# import
# docker compose $compose_file exec -T db mariadb -u root -p$MYSQL_ROOT_PASSWORD $2 < ../$3
./wrapper.sh exec dev-local  mysql-import [nama-db] [nama-import-file]
```

# Aplikasi

## WordPress

### WP Config

Pada WordPress file `wp-config.php` harus selalu terinclude ke dalam git repo, hal ini dimaksudkan agar aplikasi dari repository dapat langsung dideploy.

Setiap konfigurasi pada `wp-config.php` yang memiliki perbedaan pada environment dev, stagging dan prod wajib wrap dengan perintah berikut : 

```
define( 'API_ENV', getenv_docker('API_ENV', 'dev') );
define( 'API_KEY', getenv_docker('API_KEY', 'key') );
```

Pada contoh diatas `API_ENV` dan `API_KEY` perlu dimasukkan kedalam file `.env` pada folder `docker`

### WordPress Cache

Untuk menggunakan cache WordPress ganti php-fpm pada `nginx/sites-enabled/default.conf`

```
#include common-extra/php-fpm.conf;
#include common-extra/php-fpm-fcgi-cache.conf;
include common-extra/php-fpm-redis-cache.conf;
```

Jika halaman tidak ingin dicache bisa mengirimkan header `no-cache` hal ini bisa diatur dari halaman berikut pada WordPress `wp-admin/options-general.php?page=exclude-cache`

Secara default user tidak login akan tercache. 


### WebP Converter

Untuk mengaktfikan WebP jalankan kita dapat menggunakan docker https://hub.docker.com/r/darthsim/imgproxy/. Konfigurasi docker-compose terdapat pada file `docker/docker-compose-dev-imageproxy.yml`

Cara mengaktifkan WebP

Tambahkan host berikut

```
127.0.0.1 cdn.wordpress.local
```

Jalankan perintah berikut
```
bash wrapper.sh dev-proxy dev-local dev-imgproxy up
```

Setelah docker berjalan, akses 1 file dengan mengubah domain menjadi `cdn.wordpress.local` misalnya 

```
https://wordpress.local/wp-content/uploads/2024/06/2023-05-29_09-38.png

# versi CDN
https://cdn.wordpress.local/wp-content/uploads/2024/06/2023-05-29_09-38.png
```

Jika konversi berjalan lancar aktifkan plugin CDN pada WordPress misalnya menggunakan `cdn enabler`. 
Pada plugin `cdn enabler` input host cdn menjadi `cdn.wordpress.local`

# Tips

## Supervisorctl

Untuk mengatur service yang berjalan gunakan `supervisorctl`

```
 supervisorctl -c /home/app/supervisor/supervisord-app.conf
```


# Changelog

## 13 November 2024

- Menambahkan support redis pada Dockerfile dan juga php.ini config dinamis dari entrypoint
- Default wp_debug dirubah ke true