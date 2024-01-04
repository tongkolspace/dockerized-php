# PHP Docker Stack

Merupakah docker stack `production ready` untuk aplikasi PHP 

| Container  | Service | Deskripsi |
|------------|---------|-----------|
| reverse-proxy | reverse proxy | [traefik](https://hub.docker.com/_/traefik)  |
| php | php-fpm 8.1 | [EasyEngine php-fpm](https://hub.docker.com/r/easyengine/php/) / wordpress:6.4.1-php8.1  |
| nginx | nginx | [Nginx EE](https://hub.docker.com/r/tongkolspace/nginx-ee)  |
|       | Admin | PHPMyAdmin, Nginx Vts, etc  |
| redis | redis | [redis](https://hub.docker.com/_/redis)  |
| workspace | Cron & Supervisor | [workspace](https://hub.docker.com/r/tongkolspace/workspace) |

# Penjelasan Ringkas

```
git clone
cd docker
# Tambahan `$domain` dalam file `.env` ke hostfile
## Web hanya bisa diakses melalui `$domain`
cp .env-sample .env
# Ganti password akses dashboard
htpasswd -c docker/nginx/.htpasswd traefik
cd docker && docker compose -p nama-app up --force-recreate 
# atau
./wrapper.sh up 
```

**Sesuaikan permission**

```
cd /wordpress/
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 775 {} \;
sudo chown $(whoami):www-data . -R
```

# Environment

| Environment  | Deskripsi | Command Wrapper |
|------------|---------|-----------|
| local | Developer mengembangkan aplikasi pada environment ini | `./wrapper.sh up`
| dev | Server pengembangan yang memiliki environment mirip production | `./wrapper.sh dev up`
| prod | Server production | `./wrapper.sh prod up`

## Dev / Prod

Untuk menjalankan docker compose pada environment `dev` atau `prod` harap mengcopy : 
- `docker-compose.yml` -> `docker-compose-{env}.yml` 
- `.env-sample` -> `{env}.env`
Misal untuk environment `dev`

```
cd docker
cp docker compose.yml docker compose-dev.yml
cp .env-sample dev.env
docker compose -f docker compose-dev.yml --env-file dev.env -p nama-app up

# Sesuaikan permission di folder wordpress / laravel
cd /{app-type}/
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 775 {} \;
sudo chown $(whoami):www-data . -R
./wrapper.sh dev up  
```

Pada file `docker-compose-{env}.yml` sesuaikan konfigurasi dengan file template misalnya gunakan `php-fpm/php-prod.ini` pada aplikasi produksi

# Wrapper.sh

Untuk mempermudah development dapat menggunakan `./wrapper.sh`

```
./wrapper.sh  ?[dev|prod] [up|down|logs|restart|exec]
./wrapper.sh  ?[dev|prod] [mysql-console]
./wrapper.sh  ?[dev|prod] [mysql-dump]
./wrapper.sh  ?[dev|prod] [mysql-import] [db-name] [import-file]
./wrapper.sh  [permission] [directory]

# docker-compose up
./wrapper.sh up 
./wrapper.sh up php-fpm nginx redis

# masuk ke container db
# docker compose $compose_file exec "$@"
./wrapper.sh exec db bash

# masuk ke container workspace
./wrapper.sh exec --user=www-data workspace bash

# masuk ke console mysql
# docker compose $compose_file exec db mysql -u root -p$MYSQL_ROOT_PASSWORD
./wrapper.sh exec mysql-console

# dump db 
# docker compose $compose_file exec -T db mysqldump -u root -p$MYSQL_ROOT_PASSWORD $2 > ../$2.sql
./wrapper.sh exec mysql-dump [nama-db] 

# import
# docker compose $compose_file exec -T db mysql -u root -p$MYSQL_ROOT_PASSWORD $2 < ../$3
./wrapper.sh exec mysql-import [nama-db] [nama-import-file]

## Menjalakan docker compose-dev.yml
./wrapper.sh dev up 
./wrapper.sh restart
```
# Services

## Web App

- Aplikasi PHP http://`$domain`
- Admin Panel http://`$domain`:57710/ 

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

## Laravel

### Instalasi

copy file `.env-sample-laravel` ke `.env`
Update environment container `db` pada `docker/docker-compose.yml` agar env terbaca pada laravel

```
  db:
      environment:
        MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
        MYSQL_DATABASE: ${DB_NAME}       
        MYSQL_USER: "${DB_USER}"               
        MYSQL_PASSWORD: "${DB_PASSWORD}"       
```

Masuk ke workspace sebagai user workspace (uid=1000) untuk melakukan instalasi atau copy dari project existing

```bash
cd docker
docker compose exec -u workspace workspace bash 
cd /var/www/html
composer create-project --prefer-dist laravel/laravel .
```

Hapus konfigurasi `laravel/.env` : 

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=root
DB_PASSWORD=
```

keluar dari docker workspace ganti ownership file

```
cd /laravel
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 775 {} \;
sudo chown $(whoami):www-data . -R
```

Buka aplikasi http://`$domain`

