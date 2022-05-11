#!/usr/bin/env bash

set -e -u

# Enable debugging.
set -x

# Usage.
usage() {
  echo "Usage: cert-gen.sh [SITE_URL]" >&2
  echo "SITE-URL : URL of site to create certificate for." >&2
  exit 1
}

if [ -z "$1" ]; then
  echo "Requires the local site name as an argument, e.g: './cert-gen.sh sitename.test'" >&2
  exit
fi

if [ -z "$(docker ps -q -f name=local-reverse-proxy)" ]; then
  echo "Reverse proxy container should be running for this script to work. Start it from the docker-compose file in this directory, then try again." >&2
  exit
fi

SITE_URL="$1"

# Create a self signed certificate for the local instance.
docker exec -it local-reverse-proxy bash -c "openssl req \
  -x509 \
  -sha256 \
  -nodes \
  -days 3650 \
  -newkey rsa:2048 \
  -keyout /etc/nginx/certs/${SITE_URL}.key \
  -out /etc/nginx/certs/${SITE_URL}.crt \
  -subj '/C=US/ST=NY/L=New York/O=OCHA/OU=DS/CN=${SITE_URL}' \
  -addext 'subjectAltName=DNS:${SITE_URL}'"

# Restart the proxy container to ensure it uses the certificate.
docker-compose restart
