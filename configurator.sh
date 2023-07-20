#!/bin/bash

reset='\033[0m'

# Welcome message
echo -e "\033[0;33m\033[1mWelcome in Bux Server configurator!$reset"

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -db|--database)
        database="$2"
        shift
        ;;
        -c|--cache)
        cache="$2"
        shift
        ;;
        -bs|--bux-server)
        bux_server="$2"
        shift
        ;;
        -env|--environment)
        environment="$2"
        shift
        ;;
        -b|--background)
        background="$2"
        shift
        ;;
        -h|--help)
        echo -e "\033[1mUsage: ./configurator.sh [OPTIONS]$reset"
        echo ""
        echo "Bux configurator helps you to run Bux server with your preferred database and cache storage."
        echo ""
        echo -e "Options:$reset"
        echo -e "  -db,  --database\t Define database - postgresql, mongodb, sqlite$reset"
        echo -e "  -c,   --cache\t\t Define cache storage - freecache(in-memory), redis$reset"
        echo -e "  -bs,  --bux-server\t Whether the bux-server should be run - true/false$reset"
        echo -e "  -env, --environment\t Define bux-server environment - development/staging/production$reset"
        echo -e "  -b,   --background\t Whether the bux-server should be run in background - true/false$reset"
        exit 1;
        shift
        ;;
        *)
        ;;
    esac
    shift
done


if [ "$database" == "" ]; then
    # Ask for database choice
    echo -e "\033[1mSelect your database: $reset"
    echo "1. postgresql"
    echo "2. mongodb"
    echo "3. sqlite"
    echo -e "\033[4mAny other number ends the program $reset"
    read -p "> " database_choice

    # Validate database choice
    case $database_choice in
        1) database="postgresql";;
        2) database="mongodb";;
        3) database="sqlite";;
        *) echo -e "\033[0;31mExiting program...$reset"; exit 1;;
    esac
fi

if [ "$cache" == "" ]; then
    # Ask for cache storage choice
    echo -e "\033[1mSelect your cache storage:$reset"
    echo "1. freecache"
    echo "2. redis"
    echo -e "\033[4mAny other number ends the program $reset"
    read -p "> " cache_storage_choice

    # Validate cache storage choice
    case $cache_storage_choice in
        1) cache="freecache";;
        2) cache="redis";;
        *) echo -e "\033[0;31mExiting program...$reset"; exit 1;;
    esac
fi

# Create the .env.config file
echo -e "\033[0;32mCreating .env.config file...$reset"
cat << EOF > .env.config
BUX_CACHE__ENGINE="$cache"
BUX_DATASTORE__ENGINE="$database"
EOF

# Add additional settings to .env.config file based on the selected database
if [ "$database" == "postgresql" ]; then
    echo 'BUX_SQL__HOST="bux-postgresql"' >> .env.config
fi

# Add additional settings to .env.config file based on the selected database
if [ "$database" == "mongodb" ]; then
    echo 'BUX_MONGODB__URI="mongodb://mongo:mongo@bux-mongodb:27017/"' >> .env.config
fi

# Add additional settings to .env.config file based on the selected cache storage
if [ "$cache" == "redis" ]; then
    echo 'BUX_REDIS__URL="redis://redis:6379"' >> .env.config
fi

echo -e "\033[0;32mStarting additional services with docker-compose...$reset"
if [ "$cache" == "redis" ]; then
    echo -e "\033[0;37mdocker compose up -d bux-redis bux-'$database'$reset"
     docker compose up -d bux-redis bux-"$database"
else
    echo -e "\033[0;37mdocker compose up -d bux-'$database'$reset"
    docker compose up -d bux-"$database"
fi

if [ "$bux_server" == "" ]; then
    # Ask for bux-server choice
    echo -e "\033[1mDo you want to run Bux-server?$reset"
    echo "1. YES"
    echo "2. NO"
    echo -e "\033[4mAny other number ends the program $reset"
    read -p "> " bux_server_choice

    # Validate bux-server choice
    case $bux_server_choice in
        1) bux_server="true";;
        2) bux_server="false";;
        *) echo -e "\033[0;31mExiting program... Stopping additional services... $reset"; docker compose stop; exit 1;;
    esac
fi

if [ "$bux_server" == "true" ]; then
    if [ "$environment" == "" ]; then
        # Ask for environment choice
        echo -e "\033[1mSelect your environment:$reset"
        echo "1. development"
        echo "2. staging"
        echo "3. production"
        echo -e "\033[4mAny other number ends the program $reset"
        read -p "> " environment_choice

        # Validate environment choice
        case $environment_choice in
            1) environment="development";;
            2) environment="staging";;
            3) environment="production";;
            *) echo -e "\033[0;31mExiting program... Stopping additional services... $reset"; docker compose stop; exit 1;;
        esac
    fi

    echo "BUX_ENVIRONMENT='$environment'" >> .env.config

    if [ "$background" == "" ]; then
        # Ask for background choice
        echo -e "\033[1mDo you want ot run Bux-server in background? $reset"
        echo "1. YES"
        echo "2. NO"
        echo -e "\033[4mAny other number ends the program $reset"
        read -p "> " background_choice

        # Validate background choice
        case $background_choice in
            1) background="true";;
            2) background="false";;
            *) echo -e "\033[0;31mExiting program... Stopping additional services... $reset"; docker compose stop; exit 1;;
        esac
    fi

    echo -e "\033[0;32mRunning Bux-server...$reset"
    if [ "$background" == "true" ]; then
        echo -e "\033[0;37mdocker compose up -d bux-server$reset"
        docker compose up -d bux-server
    else
        echo -e "\033[0;37mdocker compose up bux-server$reset"
        docker compose up bux-server
    fi

else
    echo -e "\033[0;33m\033[1mThanks for using Bux configurator!"
    echo -e "Additional services are working, remember to start Bux-server manually!$reset"
    exit 1
fi


function cleanup {
    echo -e "\033[0;31mStopping additional services...$reset"
    docker compose stop
    echo -e "\033[0;31mExiting program...$reset"
}

trap cleanup EXIT
