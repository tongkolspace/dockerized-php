#!/bin/bash

function help_wrapper {
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [up|down|logs|restart|exec]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [workspace]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-console]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-dump]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-import] [db-name] [import-file]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [secure]"
    echo "./wrapper.sh  [copy_env] $sample-env $env"
    echo "./wrapper.sh  [permission] [directory]"
    echo "./wrapper.sh  [help]"
    exit 1
}

function load_env {
    # Source the .env file
    if [ -f $1 ]; then
        # Menggunakan 'set -a' untuk mengekspor semua variabel yang dibaca
        set -a
        # Membaca file tanpa menjalankan isinya
        source "$1" >/dev/null 2>&1
        set +a
        echo "load_env : $1"
    fi
}

function copy_env {
    # Define the path to the sample file and the new file
    sample_file="$script_dir/docker/$1"
    new_file="$script_dir/docker/$2"
    
    # Check if the sample file exists
    if [ ! -f "$sample_file" ]; then
        echo "Sample file does not exist: $sample_file"
        exit 1
    fi
    > "$new_file"

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ([A-Z0-9]+_PASSWORD|PASSWORD_[A-Z0-9]+)[^=]*= ]]; then
            # Detect if openssl is available for random password generation
            if command -v openssl >/dev/null 2>&1; then
                new_password=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 24)
            else
                new_password=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c 24)
            fi
            # Replace the value after '=' with the new password
            line="${line%%=*}=$new_password"
        fi
        # Write the possibly modified line to the destination file
        echo "$line" >> "$new_file"
    done < "$sample_file"


    echo "Environment file created: $new_file"
}


# Setup path
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
current_dir=$(pwd)
docker_compose_pattern="^(dev|prod|staging|pre-prod)-.*$"

if [ "$1" == "permission" ] 
then
    if [ -d "$2" ]
    then
        cd "$2"
        sudo find . -type f -exec chmod 664 {} \;
        sudo find . -type d -exec chmod 775 {} \;
        sudo chown $(whoami):www-data . -R
        cd $current_dir
        exit
    else
        echo "Directory $2 does not exist."
        exit 
    fi
elif [ "$1" == "copy_env" ]
then
    copy_env "$2" "$3"
    exit
elif [ "$1" == "help" ]
then
    help_wrapper
    exit
fi

compose_command=""
compose_file=""
compose_env=""
shift_count=0
# Set Env for docker compose
# Check if the first argument matches the pattern
if [[ ! $1 =~ $docker_compose_pattern ]]; then
    load_env "$script_dir/docker/.env-dev-local"
    compose_file="-f docker-compose-dev-local.yml"
    # compose_env="--env-file=.env"
else
    for params in "$@"; do
        if [[ $params =~ $docker_compose_pattern ]]; then
            load_env "$script_dir/docker/.env-$params"
            # Concatenate string
            compose_file="${compose_file} -f docker-compose-$params.yml"
            # compose_env="${compose_env} --env-file=.env-$params"
            ((shift_count += 1))
        else
            # If a parameter doesn't match, break out of the loop
            break
        fi
    done
fi

# shift command to remove $docker_compose_pattern
shift $shift_count

# Concatenate string
compose_command="${compose_file} -p $APP_NAME"

echo "Running with configuration : $compose_command"


if [ "$1" == "up" ]
then
    cd "$script_dir/docker"
    shift 1
    docker compose $compose_command up "$@" --force-recreate
    cd $current_dir
# elif [ "$1" == "logs" ]
# then
#     cd "$script_dir/docker"
#     docker compose $compose_command logs "$@"
#     cd $current_dir
elif [ "$1" == "secure" ] 
then
    htpasswd -bc "$script_dir/docker/nginx/.htpasswd" "$ADMIN_PANEL_USERNAME" "$ADMIN_PANEL_PASSWORD"
    echo "Admin Panel berjalan di port 57710 user = $ADMIN_PANEL_USERNAME | password = $ADMIN_PANEL_PASSWORD"
elif [ "$1" == "log-tail" ]
then
    cd "$script_dir/docker"
    docker compose $compose_command logs -t -f --tail 100
    cd $current_dir
elif [ "$1" == "mysql-console" ]
then
    cd "$script_dir/docker"
    docker compose $compose_command exec db mariadb -u root -p$MYSQL_ROOT_PASSWORD
    cd $current_dir
elif [ "$1" == "mysql-dump" ]
then

    # Check if a database name is provided
    if [ -z "$2" ]; then
        # If not provided, use either DB_NAME or DB_DATABASE
        EXPORT_DB_NAME=${DB_NAME:-$DB_DATABASE}

        if [ -z "$EXPORT_DB_NAME" ]; then
            echo "Please specify the database name"
            exit 1  # Exit the script if the database name is not provided
        fi
    else
        # Use the provided database name
        EXPORT_DB_NAME="$2"
    fi

    cd "$script_dir/docker"
    echo "Dumping database $EXPORT_DB_NAME into $script_dir/$EXPORT_DB_NAME.sql"
    docker compose $compose_command exec -T db mariadb-dump -u root -p$MYSQL_ROOT_PASSWORD $EXPORT_DB_NAME > ../$EXPORT_DB_NAME-$(date +%Y%m%d%H%M%S).sql
    cd $current_dir
elif [ "$1" == "mysql-import" ]
then

    # Check if argument is given
    if [ $# -ne 3 ]; then
        help_wrapper
        exit 1
    fi

    cd "$script_dir/docker"
    echo "import database to $2 from $script_dir/../$3"
    docker compose $compose_command exec -T db mariadb -u root -p$MYSQL_ROOT_PASSWORD $2 < ../$3
    cd $current_dir
elif [[ $2 =~ ^(workspace|node)-.*$ ]] && [[ $1 =~ ^(exec|run)$ ]]; then
    cd "$script_dir/docker"
    workspace=$2
    command=$1

    if [[ $2 =~ ^(node)-.*$ ]]; then
        user='node'
    else    
        user='workspace'
    fi

    shift 2

    # --service-port jika dibutuhkan buka semua port

    if [[ $command == 'exec' ]]; then
        docker compose $compose_command exec --user=$user $workspace "$@"
    elif [[ $command == 'run' ]]; then
        docker compose $compose_command run --rm --user=$user  $workspace "$@"
    fi

    cd $current_dir
else 

    cd "$script_dir/docker"
    docker compose $compose_command "$@"
    cd $current_dir
fi