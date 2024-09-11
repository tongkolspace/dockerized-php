# Cara Cepat
Tambahkan host berikut
```
127.0.0.1 wordpress.local proxy.dev.local
```

## Menjalankan `env` `dev-local`
```
git clone git@github.com:tongkolspace/dockerized-php.git dockerized-php && cd dockerized-php && rm .git -rf
sed -i '/^wordpress*/d' .gitignore
git init

bash wrapper.sh copy_env .env-dev-local-sample .env-dev-local
bash init.sh setup_htaccess
bash wrapper.sh dev-local up
bash init.sh download_wordpress
bash init.sh install_wordpress
```

| Sevice  | URL |
|------------|---------|
| WordPress | http://wordpress.local |
| Admin | http://wordpress.local:57710 |

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
Menggunakan images dari private registry

```
bash wrapper.sh copy_env .env-dev-container-sample .env-dev-container
bash wrapper.sh dev-local dev-container dev-proxy up
```

Pada konfigurasi ini mounting volumes hanya digunakan untuk persistance data seperti misalnya WordPress uploads folder

# Tips

## Supervisorctl

Untuk mengatur service yang berjalan gunakan `supervisorctl`

```
 supervisorctl -c /home/app/supervisor/supervisord-app.conf
```

