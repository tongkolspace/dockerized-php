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

setup_http() {
    htpasswd -bc "$script_dir/docker/nginx/.htpasswd" "$ADMIN_PANEL_USERNAME" "$ADMIN_PANEL_PASSWORD"

    sudo chown "$USER:www-data" "$script_dir/wordpress/" -R
    sudo chmod 775 "$script_dir/wordpress/" -R
    
    sudo openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -keyout "$script_dir/docker/traefik/certs/server.key" -out "$script_dir/docker/traefik/certs/server.crt"

    echo "Admin Panel berjalan di port 57710 user = $ADMIN_PANEL_USERNAME | password = $ADMIN_PANEL_PASSWORD"
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
    bash wrapper.sh run --rm -v ./wordpress:/var/www/html workspace-wordpress wp core install --url="http://$DOMAIN_WORDPRESS" --title='Site title' --admin_user='admin' --admin_password='123456' --admin_email='admin@example.com'
    echo "Akses     : http://$DOMAIN_WORDPRESS"
    echo "Username  : admin"
    echo "Password  : 123456"
}


load_env "docker/.env"
# exit
base_recipe_url=${BASE_RECIPE_URL:-https://raw.githubusercontent.com/tongkolspace/dockerized-php-recipes/main}
if [ "$1" == "install_wordpress" ]
then
    install_wordpress
elif [ "$1" == "wordpress" ]
then
    check_folder "$script_dir/$1";

    # Check if wordpress directory exists, if not create directory wordpress
    mkdir "$script_dir/wordpress"
    
    # Download WordPress
    docker run --rm -v ./wordpress:/var/www/html tongkolspace/workspace:8.1-v1.0.1 wp core download

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
    setup_http
    setup_network

    echo "Instalasi WordPress dockerized selesai, jalankan dengan : bash wrapper.sh up"
    echo "Untuk instalasi WordPress otomatis jalankan bash init.sh install_wordpress setelah menjalankan docker"

elif [ "$1" == "setup_http" ]
then
    setup_http
elif [ "$1" == "clean" ]
then
    echo "Clean WordPress and .env file.."
    sudo rm "$script_dir/wordpress" -rf
    # rm "$script_dir/docker/.env"
    # rm "$script_dir/docker/.env-dev-local"
    # rm "$script_dir/docker/.env-dev-proxy"
    sudo rm -rf "$script_dir/docker/nginx/.htpasswd"
    sudo rm -rf "$script_dir/docker/mysql/datadir/" 
else 
    echo "penggunaan"
    echo "bash init.sh install"
    echo "bash init.sh clean"
    echo "bash init.sh install_wordpress"
    echo "bash init.sh http"

fi
