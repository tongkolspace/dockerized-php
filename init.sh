# Setup path
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
current_dir=$(pwd)

# load env
function load_env {
    # Source the .env file
    if [ -f $1 ]; then
        echo "source $1"
        export $(grep -v '^#' $1 | xargs)
    else
        echo "No .env file found in $1"
        exit
    fi
}


check_folder() {
  if [ -d "$1" ]; then
    echo "Folder $1 already exists, exiting"
    exit
  fi
}

setup_htaccess() {
    htpasswd -bc "$script_dir/docker/app/nginx/.htpasswd" "$ADMIN_PANEL_USERNAME" "$ADMIN_PANEL_PASSWORD"
    echo "Admin Panel berjalan di port 57710 user = $ADMIN_PANEL_USERNAME | password = $ADMIN_PANEL_PASSWORD"
}

setup_fake_https_cert(){
        
    sudo openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -keyout "$script_dir/docker/traefik/certs/server.key" -out "$script_dir/docker/traefik/certs/server.crt"

}

setup_network() {
    # Check if the network "$NETWORK" exists
    found=$(docker network ls --format "{{.Name}}" | awk -v net="$NETWORK" '$0 == net {count++} END {print count}')
    if [ -n "$found" ]; then
        echo "Network '$NETWORK' already exists."
    else
        echo "Network '$NETWORK' does not exist, creating it..."
        docker network create $NETWORK
    fi
}

install_wordpress() {
    # Run the WordPress Install
    # bash wrapper.sh up -d
    bash wrapper.sh dev-local exec wordpress  wp core install --url="http://$DOMAIN_WORDPRESS" --title='Site title' --admin_user='admin' --admin_password='123456' --admin_email='admin@example.com'
    echo "Akses     : http://$DOMAIN_WORDPRESS"
    echo "Username  : admin"
    echo "Password  : 123456"
}

if [[ "$1" =~ ^(dev-|prod-|staging-|pre-prod-) ]]; then
    load_env "$script_dir/docker/.env-$1"
    shift 1
elif [[ "$1" != "clean" ]]; then
    load_env "$script_dir/docker/.env-dev-local"
fi
# exit
base_recipe_url=${BASE_RECIPE_URL:-https://raw.githubusercontent.com/tongkolspace/dockerized-php-recipes/main}
if [ "$1" == "install_wordpress" ]
then
    install_wordpress
elif [ "$1" == "download_wordpress" ]
then
    # Check if wordpress directory exists, if not create directory wordpress
    mkdir "$script_dir/wordpress"
    mkdir "$script_dir/wordpress_uploads"
    sudo chmod 777 "$script_dir/wordpress/" -R
    # Download WordPress
    docker run -it --rm \
    --volume "$script_dir/wordpress:/var/www/html" \
    wordpress:cli-php8.3 \
    wp core download --path=/var/www/html
    sudo chmod 775 "$script_dir/wordpress/" -R
    sudo chown "$USER:$USER" "$script_dir/wordpress/" -R

    # Install redis plugin
    if [ ! -d "$script_dir/wordpress/wp-content/mu-plugins" ]; then
        mkdir "$script_dir/wordpress/wp-content/mu-plugins"
        wget -P "$script_dir/wordpress/wp-content/mu-plugins" "$base_recipe_url/recipes/wordpress/redis-page-exclude.php"
    fi
    
    # Extra Files
    wget -P "$script_dir/wordpress" "$base_recipe_url/recipes/wordpress/wp-config.php"
    wget -O "$script_dir/wordpress/.gitignore" "$base_recipe_url/recipes/wordpress/gitignore"

    # cp "$script_dir/docker/.env-sample" docker/.env
    # cp "$script_dir/docker/.env-dev-local-sample" docker/.env-dev-local
    # cp "$script_dir/docker/.env-dev-proxy-sample" docker/.env-dev-proxy
    # setup_htaccess
    setup_fake_https_cert
    setup_network

    echo "Untuk instalasi WordPress otomatis jalankan bash init.sh install_wordpress"

elif [ "$1" == "setup_htaccess" ]
then
    setup_htaccess
elif [ "$1" == "setup_fake_https_cert" ]
then
    setup_fake_https_cert
elif [ "$1" == "clean" ]
then
    echo "Clean WordPress and .env file.."
    rm "$script_dir/wordpress" -rf
    rm "$script_dir/docker/.env-dev-local"
    rm "$script_dir/docker/.env-dev-tongkolspace"
    rm "$script_dir/docker/.env-dev-tongkolspace-k8"
    rm "$script_dir/docker/.env-dev-proxy"
    sudo rm -rf "$script_dir/docker/app/nginx/.htpasswd"
    sudo rm -rf "$script_dir/docker/mysql/datadir/" 
else 
    echo "penggunaan"
    echo "bash init.sh clean"
    echo "bash init.sh download_wordpress"
    echo "bash init.sh install_wordpress"
    echo "bash init.sh setup_htaccess"
    echo "bash init.sh setup_fake_https_cert"

fi
