# Cara Cepat
Tambahkan host berikut
```
127.0.0.1 wordpress.local proxy.dev.local
```

## Menjalankan `env` local
```
git clone git@github.com:tongkolspace/dockerized-php.git dockerized-php && cd dockerized-php && rm .git -rf
sed -i '/^wordpress\/\*/d' .gitignore
git init

#cp docker/.env-sample docker/.env
bash wrapper.sh copy_env .env-dev-local-sample .env-dev-local
bash init.sh download_wordpress

# State up docker compose
bash wrapper.sh dev-local up
```

| Sevice  | URL |
|------------|---------|
| WordPress | http://wordpress.local |
| Admin | http://wordpress.local:57710 |

## Menjalankan `env` dev-tonjoo

```
bash wrapper.sh dev-local down

# Ganti password pada file .env-dev-local dan .env-dev-tongkolspace
bash wrapper.sh copy_env .env-dev-local-sample .env-dev-local
bash wrapper.sh copy_env .env-dev-tongkolspace-sample .env-dev-tongkolspace

bash wrapper.sh dev-local dev-tongkolspace up
```
| Sevice  | URL |
|------------|---------|
| WordPress | https://wordpress.local |
| Admin | https://wordpress.local:57710 |

## Menjalankan `env` dev-tonjoo + traefik
```
bash wrapper.sh dev-local down

# Ganti password pada file .env-dev-local dan .env-dev-tongkolspace
bash wrapper.sh copy_env .env-dev-local-sample .env-dev-local
bash wrapper.sh copy_env .env-dev-tongkolspace-sample .env-dev-tongkolspace
bash wrapper.sh copy_env .env-dev-proxy-sample .env-dev-proxy

bash wrapper.sh dev-local dev-tongkolspace up
```
| Sevice  | URL |
|------------|---------|
| WordPress | https://wordpress.local |
| Admin | https://wordpress.local:57710 |
| Admin Traefik | https://wordpress.local:57712 |

# PHP Docker Stack

Merupakah docker stack `production ready` untuk aplikasi PHP 

| Service  | Stack | Folder  | URL Domain |  Deskripsi |
|------------|---------|-----------|-----------|-----------|
| Admin Panel | nginx | `admin`| wordpress.local:57710 |  Admin tools (phpmyadmin etc)  |
|   | nginx,traefik | `admin` | wordpress.local:57712 |  Traefik Dashboard  |
| CMS | WordPress| `wordpress` | wordpress.local |  WordPress  |



# Wrapper.sh

Untuk mempermudah management docker-compose gunakan file `./wrapper.sh`

```
./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [up|down|logs|restart|exec]
./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-console]
./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-dump]
./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-import] [db-name] [import-file]
./wrapper.sh  [permission] [directory]

# docker-compose up
./wrapper.sh up 
./wrapper.sh up php-fpm nginx redis


# Menjalankan beberapa environment
./wrapper.sh dev-local dev-proxy up 

# masuk ke container db
./wrapper.sh exec db bash

# Menjalankan container workspace
./wrapper.sh run --rm --user=www-data workspace-wordpress bash

# masuk ke console mysql
# docker compose $compose_file exec db mysql -u root -p$MYSQL_ROOT_PASSWORD
./wrapper.sh exec mysql-console

# dump db 
# docker compose $compose_file exec -T db mysqldump -u root -p$MYSQL_ROOT_PASSWORD $2 > ../$2.sql
./wrapper.sh exec mysql-dump [nama-db] 

# import
# docker compose $compose_file exec -T db mysql -u root -p$MYSQL_ROOT_PASSWORD $2 < ../$3
./wrapper.sh exec mysql-import [nama-db] [nama-import-file]

```


# Environment

| Environment  | docker-compose | Penjelasan |
|------------|---------|-----------|
| dev local | docker-compose-dev-local.yml | Tempat developer mengembangkan aplikasi menggunakan config mysql dan php development | 
| dev tonjoo | docker-compose-dev-local.yml | | 
|                    | docker-compose-dev-tongkolspace.yml | Environment development dengan traefik + nginx. Aplikasi dijalankan dengan config php dan mysql production |
| dev proxy| docker-compose-dev-proxy.yml | Environment untuk menjalankan service traefik sebagai service proxy| 
| production | docker-compose-prod-app.yml | Environment production | 


Untuk membuat environment baru perlu dibuat 2 file yaitu file `docker-compose-{nama-env}` dan `.env-{nama-env}`

Misal kita ingin membuat environment `prod-aws` maka perlu dibuat

- `docker-compose-prod-aws`
- `.env-prod-aws`

Jalankan dengan `wrapper.sh prod-aws up`


# Services

## Web App

- Aplikasi WordPress http://wordpress.local`
- Admin Panel http://wordpress.local:57710/ 
  - Gunakan user dan password pada file .env sesuai environment

## Background Job

cron : `docker/workspace/cron-{APP-TYPE}`
supervisor : `supervisor.d/{APP-TYPE}.conf`

Supervisor dan cron harus berjalan dengan user `www-data`

```
# Cron 
* * * * * su -s /bin/sh www-data -c '/usr/local/bin/wp cron event run --due-now --path=/var/www/html/wp' > /proc/1/fd/1 2>&1
00 04 * * * su -s /bin/sh www-data -c '/usr/local/bin/wp cache flush --path=/var/www/html/wp' > /proc/1/fd/1 2>&1
```

## Eksekusi Command Container

Gunakan container `workspace` untuk menjalankan perintah `wp` atau `npm`. 
Pada dev / prod perintah harus dijalankan sebagai `www-data` dengan cara menggunakan wrapper `exec-www` atau masuk sebagai www-data

```bash
# Contoh 1
docker compose exec workspace bash
exec-www wp core udate

# Contoh 2
./wrapper.sh  exec -u www-data workspace bash 
wp core udate
```

## MySQL

Akses MySQL

```
docker compose exec db bash
mysql -u root -p$MYSQL_ROOT_PASSWORD
```

Untuk melakukan import data mysql 

```
docker compose exec -T db mysql -u $USER -p$PASSWORD DB_NAME < file.sql
./wrapper.sh exec -T db mysql -u $USER -p$PASSWORD DB_NAME < file.sql
```

## Konfigurasi php.ini

sesuaikan php ini sesuai kebutuhan pada php-fpm/php-(dev|prod).ini

## Nginx 

Sesuaikan upstream service docker php fpm dan redis pada `nginx/conf.d-extra` jika dibutuhkan. Pastikan berjalan dengan user www-data

## Traefik
Service ini berada di dalam file `docker-compose-dev-proxy.yml`. Service traefik bisa diaktifkan pada server yang belum terdapat traefik ataupun pada pengujian `dev-tonjoo + traefik` di localhost. Untuk bisa menggunakan service traefik diperlukan ssl yang bisa dibuat dengan step berikut ini:
```
cd /proyek_docker/docker/traefik/certs
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout server.key -out server.crt
```

# Ownership

Ownership file pada docker  perlu  diperhatikan dengan seksama. Volume yang di-mount pada docker container akan memiliki GUID dan UID yang sama dengan GUID dan UID pada host machine

Untuk melihat UID dan GUID dapat dicek dengan perintah `id`

```bash
#Container
$id www-data
uid=33(www-data) gid=33(www-data) groups=33(www-data)

#Host
$id www-data
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

User kasatka memiliki uid 1000 yang merupakan uid pertama non root dalam sistem linux. Jika  kita melakukan mount folder `/var/www/html` maka pada docker container dengan user kasatka maka akan terdeteksi UID file dan folder adalah 1000, hal ini dikarenakan user kasatka tidak terbaca dalam container linux maka dari itu ownershipnya menggunakan uid = 1000 seperti pada contoh dibawah ini

```bash
docker compose exec nginx bash
# ls -lsa
total 424508
     4 drwxrwxr-x 170     1000 www-data      4096 Nov 22 18:40  .
     4 drwxr-xr-x   3 root     root          4096 Nov 22 18:50  ..
     4 drwxrwxr-x   3     1000 www-data      4096 Nov 30  2019  .fr-WGqm8M
     4 drwxrwxr-x   3     1000 www-data      4096 Mar 27  2020  .well-known
```

Dalam web development biasanya user biasanya memiliki group  yang sama dengan www-data (gid=33). 
Agar tidak terjadi konflik sangat penting ketika melakukan perintah di server untuk menggunakan user www-data atau user dengan UID=1000(workspace)

```bash
# masuk sebagai user www-data (uid=33)
./wrapper.sh dev exec nginx bash 

# masuk sebagai user workspace (uid=1000)
./wrapper.sh dev exec --user=workspace nginx  bash 
```

## Strategi File Permission

Pada mesin `dev`/`local`/`prod` pastikan ada user www-data dengan uid=33, kemudian tambahkan user saat ini kedalam group www-data

```bash
# Cek userid www-data
id www-data
# Jika tidak ada tambahkan user www-data dengan uid=33
sudo addgroup --system --gid 33 www-data
sudo adduser --system --uid 33 --gid 33 --no-create-home www-data
# tambahkan user saat ini ke www-data
sudo usermod -a -G www-data $(whoami)
```
  
Gunakan permission group write agar baik developer (UID=1000) dan user www-data (UID=33) pada docker bisa write

```bash
cd /folder-project/
sudo find . -path './wp-content/uploads' -prune -o -type f -exec bash -c 'chown $(whoami):www-data {} && chmod 664 {}' \;
sudo find . -path './wp-content/uploads' -prune -o -type d -exec bash -c 'chown $(whoami):www-data {} && chmod 775 {}' \;
```

Perubahan ownership folder dan file akan merubah git, maka dari itu cukup lakukan 1x saja agar tidak memenuhi commit pada repository git.

**Extra Proctection**

Pada beberapa environment owner dan group dari folder dan file harus www-data.

Konsekuensi dari hal ini : 

- Tidak bisa write ke file sebagai user
- Semua cron dan background job menggunakan user `www-data`

```bash
cd /folder-project/
sudo find . -type f -exec chmod 644 {} \;
sudo find . -type d -exec chmod 755 {} \;
sudo find wp-content -type f -exec chmod 775 {} \;
sudo chmod 775 wp-config.php
sudo chown www-data:www-data . -R
```

Perubahan ownership dan permission diatas idealnya dilakukan menggunakan script deploy dan tidak dimasukkan ke dalam git

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
