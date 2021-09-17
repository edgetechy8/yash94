#!/bin/bash

# Script accepts a single argument, the fqdn for the cert
DOMAIN="play99_bet.com"
if [ -z "$DOMAIN" ]; then
  echo "Usage: $(basename $0) <domain>"
  exit 11
fi

fail_if_error() {
  [ $1 != 0 ] && {
    unset PASSPHRASE
    exit 10
  }
}

# Generate a passphrase
export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo)

# Certificate details; replace items in angle brackets with your own info
subj="
C=US
ST=OR
O=Blah
localityName=Portland
commonName=$DOMAIN
organizationalUnitName=Blah Blah
emailAddress=admin@example.com
"

# Generate the server private key
openssl genrsa -des3 -out $DOMAIN.key -passout env:PASSPHRASE 2048
fail_if_error $?

# Generate the CSR
openssl req \
    -new \
    -batch \
    -subj "$(echo -n "$subj" | tr "\n" "/")" \
    -key $DOMAIN.key \
    -out $DOMAIN.csr \
    -passin env:PASSPHRASE
fail_if_error $?
cp $DOMAIN.key $DOMAIN.key.org
fail_if_error $?

# Strip the password so we don't have to type it every time we restart Apache
openssl rsa -in $DOMAIN.key.org -out $DOMAIN.key -passin env:PASSPHRASE
fail_if_error $?

# Generate the cert (good for 10 years)
openssl x509 -req -days 365 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
fail_if_error $?

# Copy the key and crt file to correct direction

mv $DOMAIN.key /etc/pki/tls/private/
mv $DOMAIN.crt /etc/pki/tls/certs/

# change old domain name to new from the /etc/httpd/conf.d/play55_test.conf file

sed -i 's/13.229.59.17/play99_bet.com/g' /etc/httpd/conf.d/play55_test.conf

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-de64dc9e.efs.ap-southeast-1.amazonaws.com:/ ~/efs-mount-point/
