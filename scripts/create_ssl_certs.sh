#!/usr/bin/env bash
mkdir -p ssl_certs
openssl req -newkey rsa:2048 -nodes -keyout ./ssl_certs/localhost.key -x509 -days 365 -out ./ssl_certs/localhost.crt