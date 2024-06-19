#!/bin/bash

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

domains=(your_domain.com)
rsa_key_size=4096
data_path="./data/certbot"
email="your_email@example.com" # Adding a valid address is strongly recommended
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

if [ -d "$data_path" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

mkdir -p "$data_path/conf"
mkdir -p "$data_path/www"

docker-compose run --rm --entrypoint "\
  mkdir -p /var/www/certbot \
  && cp -r /var/www/certbot /data/letsencrypt/www" certbot

docker-compose run --rm --entrypoint "\
  openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 4096" certbot

compose_cmd="docker-compose run --rm --entrypoint"

$compose_cmd "\
  certbot certonly --webroot -w /var/www/certbot \
  --email $email \
  -d ${domains[*]} \
  --rsa-key-size $rsa_key_size \
  --agree-tos \
  --force-renewal" certbot

docker-compose exec nginx nginx -s reload
