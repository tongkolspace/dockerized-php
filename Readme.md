# PHP Docker Stack

Merupakah docker stack `production ready` untuk aplikasi PHP 

| Container  | Service | Deskripsi |
|------------|---------|-----------|
| reverse-proxy | reverse proxy | [traefik](https://hub.docker.com/_/traefik)  |
| php | php-fpm 8.1 | [EasyEngine php-fpm](https://hub.docker.com/r/easyengine/php/) / wordpress:6.4.1-php8.1  |
| nginx | nginx | [Nginx EE](https://hub.docker.com/r/tongkolspace/nginx-ee)  |
| redis | redis | [redis](https://hub.docker.com/_/redis)  |
| workspace | Cron & Supervisor | [workspace](https://hub.docker.com/r/tongkolspace/workspace) |

# Penjelasan Ringkas


```
git clone
cd docker
# Tambahan domain dalam file `.env` ke hostfile
cp .env-sample .env
docker compose -p nama-app up --force-recreate 
# atau jika hanya butuh web service saja
docker compose up nginx workspace
```


**Sesuaikan permission**
```
cd /wordpress/
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 775 {} \;
sudo chown $(whoami):www-data . -R
```

**Prod / Stagging**

Untuk menjalankan docker compose pada environment dev harap mengcopy docker compose.yml dan .env-sample

```
cd docker
cp docker compose.yml docker compose-dev.yml
cp .env-sample dev.env
docker compose -f docker compose-dev.yml --env-file dev.env -p nama-app up 
```

Gunakan `php-fpm/php-prod.ini` pada aplikasi produksi

**Sesuaikan permission**

```
cd /folder-project/
sudo find . -type f -exec chmod 644 {} \;
sudo find . -type d -exec chmod 755 {} \;
sudo find wp-content -type f -exec chmod 775 {} \;
sudo chmod 775 wp-config.php
sudo chown www-data:www-data . -R
```

## Wrapper.sh


Untuk mempermudah development dapat menggunakan `./wrapper.sh`

```
./wrapper.sh help
Usage : ./wrapper.sh  ?[dev|prod] [up|down|logs|restart|exec]
Usage : ./wrapper.sh  [permission] [folder]

# docker-compose up
./wrapper.sh up 
./wrapper.sh up php-fpm nginx redis

# masuk ke container db
./wrapper.sh exec db bash

# masuk ke console mysql
./wrapper.sh exec mysql-console

# dump db
./wrapper.sh exec mysql-dump [nama-db]

# import
./wrapper.sh exec mysql-import [nama-db] [nama-import-file]

## Menjalakan docker compose-dev.yml
./wrapper.sh dev up 
./wrapper.sh restart
```



# Services

## Web App

- Aplikasi PHP http://domain
- PHPMyAdmin http://domain/pma/ 

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

**MySQL**

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


# WordPress Cache

Untuk menggunakan cache WordPress ganti php-fpm pada `nginx/sites-enabled/default.conf`

```
#include common-extra/php-fpm.conf;
include common-extra/php-fpm-redis-cache.conf;
```

Secara default user tidak login akan tercache. 
Jika halaman tidak ingin dicache bisa mengirimkan header `no-cache` 
Untuk mengatur exclude cache buka halaman berikut pada WordPress `wp-admin/options-general.php?page=exclude-cache`


# Instalasi laravel

Ganti `APP_TYPE=laravel` pada `docker/.env`

Update environment container `php-fpm` dan `workspace` pada `docker/docker compose.yml` agar env terbaca pada laravel

```
DB_HOST: "${DB_HOST}"
DB_DATABASE: "${DB_NAME}"
DB_USERNAME: "${DB_USER}"
DB_PASSWORD: "${DB_PASSWORD}"
APP_DEBUG: "${DEBUG}"
```

Masuk ke workspace sebagai user workspace (uid=1000) untuk melakukan instalasi atau copy dari project existing

```bash
cd docker
docker compose exec -u workspace workspace bash 
cd /var/www/html
composer create-project --prefer-dist laravel/laravel .
```

Ganti `laravel/.env` pada laravel

```
DB_CONNECTION=mysql
DB_HOST=DB_HOST
DB_PORT=3306
DB_DATABASE=DB_NAME
DB_USERNAME=DB_USER
DB_PASSWORD=DB_PASSWORD
```

keluar dari docker workspace ganti ownership file

```
cd /laravel
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 775 {} \;
sudo chown $(whoami):www-data . -R
```

Jalankan composer install dan perintah lainya yang diperlukan kemudian buka aplikasi di : http://domain

# Ownership

Ownership file pada dokcer  perlu  diperhatikan dengan seksama. Volume yang di-mount pada docker container akan memiliki GUID dan UID yang sama dengan GUID dan UID pada host machine

Untuk melihat UID dan GUID dapat dicek dengan perintah `id`

```bash
$ id
uid=1000(kasatka) gid=1000(kasatka) groups=1000(kasatka)

```
User kasatka memiliki uid 1000 yang merupakan uid pertama non root dalam sistem linux. Jika  kita melakukan mount folder `/var/www/html` maka pada docker container dengan user kasatka maka akan terdeteksi UID file dan folder adalah 1000, hal ini dikarenakan user kasatka tidak terbaca dalam container linux maka dari itu ownershipnya menggunakan uid = 1000

```bash
docker compose exec nginx bash
# ls -lsa
total 424508
     4 drwxrwxr-x 170     1000 www-data      4096 Nov 22 18:40  .
     4 drwxr-xr-x   3 root     root          4096 Nov 22 18:50  ..
     4 drwxrwxr-x   3     1000 www-data      4096 Nov 30  2019  .fr-WGqm8M
     4 drwxrwxr-x   3     1000 www-data      4096 Mar 27  2020  .well-known
```

Dalam web development biasanya user biasanya memiliki group  yang sama dengan www-data (gid=33). Agar tidak terjadi konflik sangat penting ketika melakukan perintah di server untuk menggunakan user www-data, karena user www-data secara universal memiliki uid=33

```bash
Container
# id www-data
uid=33(www-data) gid=33(www-data) groups=33(www-data)

Host
$id www-data
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

## Strategi File Permission

Pada mesin dev pastikan ada user www-data dengan uid=33, kemudian tambahkan user saat ini kedalam group www-data

```bash
sudo addgroup --system --gid 33 www-data
sudo adduser --system --uid 33 --gid 33 --no-create-home www-data
sudo usermod -a -G www-data $(whoami)
```
  
Pada mesin local gunakan  permission group write agar baik developer (UID=1000) dan user www-data (UID=33) pada docker bisa write

```bash
cd /folder-project/
sudo find . -type f -exec chmod 664 {} \;
sudo find . -type d -exec chmod 775 {} \;
sudo chown $(whoami):www-data . -R
```

Pada mesin docker perlu dirubah permision waktu deploy , seharusnya cukup dirubah 1 x
Jangan merubah permission ke file 644 dan directory 755 di local karena akan merubah commit git

**dev / prod**
```bash
cd /folder-project/
sudo find . -type f -exec chmod 644 {} \;
sudo find . -type d -exec chmod 755 {} \;
sudo find wp-content -type f -exec chmod 775 {} \;
sudo chmod 775 wp-config.php
sudo chown www-data:www-data . -R
```

# Penjelasan cara kerja WordPress

Pada WordPress file `wp-config.php` harus selalu terinclude ke dalam git repo, hal ini dimaksudkan agar aplikasi dari repository dapat langsung dideploy.
Setiap konfigurasi pada `wp-config.php` yang memiliki perbedaan pada environment dev, stagging dan prod wajib wrap dengan perintah berikut : 

```
define( 'API_ENV', getenv_docker('API_ENV', 'dev') );
define( 'API_KEY', getenv_docker('API_KEY', 'key') );
```

Pada contoh diatas `API_ENV` dan `API_KEY` perlu dimasukkan kedalam file `.env` pada folder `docker`



# Todo 
- [x] Supervisor
- [x] Redis
- [x] Cron
- [x] Admin -> di server nginx
     - [ ] PHPMyAdmin
     - [ ] RedisAdmin
     - [ ] NginxVTS
- [ ] Deploy Script
     - [ ] WordPress
- [x] Nginx
     - [x] Security (docker,upload)ls
     - [x] Optimasi performace
     - [x] Redis cache
- [x] Implement dev
- [x] Implement prod