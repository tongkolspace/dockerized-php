#!/bin/bash

function help_wrapper {
    echo "Usage : ./wrapper.sh  ?[dev|prod] [up|down|logs|restart|exec]"
    echo "Usage : ./wrapper.sh  permission directory"
    exit 1
}


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


if [ "$1" == "dev" ] || [ "$1" == "prod" ]
then
    compose_file="-f docker-compose-$1.yml --env-file=$1.env"
    shift 1    
else   
    compose_file="-f docker-compose.yml --env-file=.env"
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
elif [ "$1" == "exec" ]
then
    cd "$script_dir/docker"
    shift 1
    docker compose $compose_file exec "$@"
    cd $current_dir    
else 
    help_wrapper
fi

