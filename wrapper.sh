#!/bin/bash

function help_wrapper {
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [up|down|logs|restart|exec]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [workspace]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-console]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-dump]"
    echo "./wrapper.sh  ?[dev-*|prod-*|staging-*|pre-prod-*] [mysql-import] [db-name] [import-file]"
    echo "./wrapper.sh  [permission] [directory]"
    echo "./wrapper.sh  [help]"
    exit 1
}

function load_env {
    # Source the .env file
    if [ -f $1 ]; then
        echo "source $1"
        export $(grep -v '^#' $1 | xargs)
    else
        echo "No .env file found in $1"
    fi
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
    load_env "$script_dir/docker/.env"
    compose_file="-f docker-compose.yml"
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
elif [ "$1" == "log-tail" ]
then
    cd "$script_dir/docker"
    docker compose $compose_command logs -t -f --tail 100
    cd $current_dir
elif [ "$1" == "mysql-console" ]
then
    cd "$script_dir/docker"
    docker compose $compose_command exec db mysql -u root -p$MYSQL_ROOT_PASSWORD
    cd $current_dir
elif [ "$1" == "mysql-dump" ]
then

    if [ "$2" == "" ]; then

        EXPORT_DB_NAME=${DB_NAME:-$DB_DATABASE}

        if [ -z "$EXPORT_DB_NAME" ]; then
            echo "Please specify db name"
        fi
    fi

    cd "$script_dir/docker"
    echo "Dumping database $EXPORT_DB_NAME into $script_dir/../$EXPORT_DB_NAME.sql"
    docker-compose $compose_command exec -T db mysqldump -u root -p$MYSQL_ROOT_PASSWORD $EXPORT_DB_NAME > ../$EXPORT_DB_NAME$(date +%Y%m%d%H%M%S).sql
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
    docker compose $compose_command exec -T db mysql -u root -p$MYSQL_ROOT_PASSWORD $2 < ../$3
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
        docker-compose $compose_command exec --user=$user $workspace "$@"
    elif [[ $command == 'run' ]]; then
        docker-compose $compose_command run --rm --user=$user  $workspace "$@"
    fi

    cd $current_dir
else 

    cd "$script_dir/docker"
    docker compose $compose_command "$@"
    cd $current_dir
fi