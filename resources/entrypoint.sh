#!/usr/bin/env /bin/bash

set -e

echo "-- Preparing site configuration file --"
OMEROWEBHOST="${OMEROWEBHOST:-}"
PROTOCOL="${VIRTUAL_PROTO:-http}"

if [ -z $OMEROWEBHOST ]; then
    echo "No OMEROWEBHOST specified, exit!"
    exit 125
fi

if [ $PROTOCOL == "http" ]; then
    echo "Enabling HTTP protocol"
    envsubst '${OMEROWEBHOST}' < /etc/nginx/templates/ome_seadragon_http.template > /etc/nginx/sites-enabled/ome_seadragon.conf
elif [ $PROTOCOL == "https" ]; then
    echo "Enabling HTTPS protcol"
    envsubst '${OMEROWEBHOST},${VIRTUAL_HOST}' < /etc/nginx/templates/ome_seadragon_https.template > /etc/nginx/sites-enabled/ome_seadragon.conf
else
    echo "${PROTOCOL} is not a valid one"
    exit 125
fi

echo "-- Starting nginx server --"
nginx -g 'daemon off;'
