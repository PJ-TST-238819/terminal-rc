#!/bin/bash

DC_FILE=/home/mother/git/remax/manticore/docker-compose.yml

# Start the docker compose service from the DC_FILE location
docker compose -f $DC_FILE up -d

# Check if the service is running
if ! docker compose -f $DC_FILE ps | grep -q 'Up'; then
    echo "Manticore service is not running."
    exit 1
fi

docker compose -f $DC_FILE exec -it rest-api bash /var/www/scripts/open-tunnel.sh
