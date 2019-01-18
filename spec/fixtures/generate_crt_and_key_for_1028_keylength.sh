#!/bin/bash

# Creating working directory
WORKINGDIR=$(echo $PWD)
TEMPDIR=$(mktemp -d)
cd $TEMPDIR

# 1. Creating a private key  
openssl genrsa -out key_for_weak_key_cert.pem 1024

# 2. Creating a certificate request 
openssl req -verbose -new -key key_for_weak_key_cert.pem -out ca.csr \
            -subj "/C=US/ST=WA/L=Seattle/O=SUSE/OU=CaaSP/CN=1024 key length"

# 3. Generating an openssl environment in the working directory (where the files are located at with SUSE OS)
mkdir -p ./demoCA/newcerts
touch ./demoCA/index.txt
touch ./demoCA/index.txt.attr 
echo 01 > ./demoCA/serial

# 4. Signing the certificate Request
openssl ca -batch -extensions v3_ca -out weak_key_cert.pem -keyfile key_for_weak_key_cert.pem \
	-selfsign -md sha256 -days 10000 -infiles ca.csr

# 5. move the certificate and key
mv weak_key_cert.pem $WORKINGDIR
mv key_for_weak_key_cert.pem $WORKINGDIR
cd $WORKINGDIR

# 6. Check 
openssl x509 -noout -text -in weak_key_cert.pem

# 7. cleanup
rm -r $TEMPDIR
