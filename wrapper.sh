#!/bin/bash

function help_wrapper {
    echo "Usage : ./wrapper.sh  ?[dev|prod] [up|down|logs|restart|exec]"
    echo "Usage : ./wrapper.sh  ?[dev|prod] [mysql-console]"
    echo "Usage : ./wrapper.sh  ?[dev|prod] [mysql-dump]"
    echo "Usage : ./wrapper.sh  ?[dev|prod] [mysql-import] [db-name] [import-file]"
    echo "Usage : ./wrapper.sh  permission directory"
    exit 1
}

function load_env {
    # Source the .env file
    if [ -f $1 ]; then
        export $(grep -v '^#' $1 | xargs)
    else
        echo "No .env file found in $1"
    fi
}

# Check if argument is given
if [ $# -eq 0 ]; then
    help_wrapper
    exit 1
fi

# Setup path
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
current_dir=$(pwd)


if [ "$1" == "permission" ] 
then
    if [ -d "$2" ]
    then
        cd "$2"
        sudo find . -type f -exec chmod 664 {} \;
        sudo find . -type d -exec chmod 775 {} \;
        sudo chown -R www-data:www-data .
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

# Set Env for docker compose
if [ "$1" == "dev" ] || [ "$1" == "prod" ]
then
    load_env "$script_dir/docker/$1.env"
    compose_file="-f docker-compose-$1.yml --env-file=$1.env -p $APP_NAME"
    shift 1    
else   
    load_env "$script_dir/docker/.env"
    compose_file="-f docker-compose.yml --env-file=.env -p $APP_NAME"
fi

echo "Running with configuration : $compose_file"

if [ "$1" == "down" ]
then
    cd "$script_dir/docker"
    shift 1
    docker compose $compose_file down "$@"
    cd $current_dir
elif [ "$1" == "restart" ]
then
    cd "$script_dir/docker"
    shift 1
    docker compose $compose_file restart "$@"
    cd $current_dir
elif [ "$1" == "up" ]
then
    cd "$script_dir/docker"
    shift 1
    docker compose $compose_file up "$@" --force-recreate -d
    cd $current_dir
elif [ "$1" == "log" ]
then
    cd "$script_dir/docker"
    docker compose $compose_file logs -t -f --tail 100
    cd $current_dir
elif [ "$1" == "mysql-console" ]
then
    cd "$script_dir/docker"
    docker compose $compose_file exec db mysql -u root -p$MYSQL_ROOT_PASSWORD
    cd $current_dir
elif [ "$1" == "mysql-dump" ]
then

    if [ "$2" == "" ]; then
        $2 = $DB_NAME
    fi

    cd "$script_dir/docker"
    echo "Dumping database $2 into $2.sql"
    docker compose $compose_file exec -T db mysqldump -u root -p$MYSQL_ROOT_PASSWORD $2 > ../$2.sql
    cd $current_dir
elif [ "$1" == "mysql-import" ]
then

    # Check if argument is given
    if [ $# -ne 3 ]; then
        help_wrapper
        exit 1
    fi

    echo "import database to $2 from $3"
    cd "$script_dir/docker"
    docker compose $compose_file exec -T db mysql -u root -p$MYSQL_ROOT_PASSWORD $2 < ../$3
    cd $current_dir
elif [ "$1" == "exec" ]
then
    cd "$script_dir/docker"
    shift 1
    docker compose $compose_file exec "$@"
    cd $current_dir    
else 
    help_wrapper
fi

