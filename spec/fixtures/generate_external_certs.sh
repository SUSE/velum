#!/bin/bash

# This script re-generates all of the keys and certs within the external_certs directory.
# The files there are used by the spec/features/settings/external_cert_feature_spec test

function init() {
  mkdir -p /tmp/ca_gen/csr
  CSR_DIR=/tmp/ca_gen/csr
  
  mkdir -p /tmp/ca_gen/certs
  DIR_CERTS=/tmp/ca_gen/certs
  
  mkdir -p /tmp/ca_gen/conf
  DIR_CONF=/tmp/ca_gen/conf
  
  mkdir -p /tmp/ca_gen/keys
  DIR_KEYS=/tmp/ca_gen/keys
  
  mkdir -p /tmp/ca_gen/cadata
  DIR_CADATA=/tmp/ca_gen/cadata
  
  echo "dir cadata: $DIR_CADATA"
}

function cleanup() {
  rm -rf /tmp/ca_gen
}

function init_ca() { # $1 ca_name
  echo "Initiating CA  \"$1\""
  generate_conf $1
  # Create / clear certs directory for CA
  mkdir -p $DIR_CADATA/$1/db.certs
  rm $DIR_CADATA/$1/db.certs/* 2>/dev/null
  
  # Create / clear index file of certs
  rm $DIR_CADATA/$1/db.inde* 2>/dev/null
  touch $DIR_CADATA/$1/db.index
  
  # Other basic needed files
  echo unique_subject = yes > $DIR_CADATA/$1/db.index.attr
  echo 01 > $DIR_CADATA/$1/db.serial
  
  # Create the keyfile for the CA
  openssl genrsa -out $DIR_KEYS/ca_$1.key 2>/dev/null
}

function init_root_ca() { # $1 ca_name, $2 subject
  init_ca $1
  echo "Generating CRT \"$1\""
  openssl req -new -x509 -days 100 -extensions v3_ca -key $DIR_KEYS/ca_$1.key -out $DIR_CERTS/ca_$1.crt -subj "$2"
}

function init_sub_ca() { # $1 ca_name, $2 parent_ca, $3 subject
  init_ca $1
  echo "Generating CRT \"$1\""
  openssl req -sha256 -new -key $DIR_KEYS/ca_$1.key -out $CSR_DIR/ca_$1.csr -subj "$3"
  openssl ca -batch \
    -config $DIR_CONF/ca_$2.conf \
    -extensions v3_ca \
    -out $DIR_CERTS/ca_$1.crt \
    -infiles $CSR_DIR/ca_$1.csr 2>/dev/null
}

function append_altnames() { # $1 altnames, $2 filename
  IFS='-' read -r -a altnames <<< "$1"
  for index in "${!altnames[@]}"
  do
      echo "DNS.$(($index+1)) = ${altnames[index]}" >> $2
  done
}

function append_ip_altnames() { # $1 altnames, $2 filename
  IFS='-' read -r -a altnames <<< "$1"
  for index in "${!altnames[@]}"
  do
      echo "IP.$(($index+1)) = ${altnames[index]}" >> $2
  done
}

function site_request_conf() { # $1 file, $2 bits
  echo "[req]" > $1
  echo default_bits = $2 >> $1
  echo distinguished_name = req_distinguished_name >> $1
  echo req_extensions = req_ext >> $1
  
  # Various prompts for the portions of the subject would go here, as well as defaults.
  # They can, though, be left blank when the subject is provided on the command line.
  cat >>$1 <<EOL
[req_distinguished_name]
EOL
  
  echo -e "[req_ext]\nsubjectAltName = @alt_names\n" >> $1
  echo -e "[alt_names]" >> $1
}

function gen_start_end() { # $1 good/expired
  # Right now we are just using harded good/bad for the date range validity.
  # For most purposes it would be better to expose the clean text specification
  # of both start and end as parameters.
  if [ $1 = "good" ]
  then
    START_DATE=$(TZ=UTC date +"%Y%m%d%H%M%SZ" -d "-1 day")
    END_DATE=$(TZ=UTC date +"%Y%m%d%H%M%SZ" -d "+100 days")
  else
    START_DATE=$(TZ=UTC date +"%Y%m%d%H%M%SZ" -d "-10 day")
    END_DATE=$(TZ=UTC date +"%Y%m%d%H%M%SZ" -d "-5 days")
  fi
}

function create_site_crt() { # $1 domain, $2 ca, $3 message_digest, $4 rsa_bits, $5 good/expired, $6 subject, $7 altnames, $8 ipaltnames
  echo "Generating site key \"$1\""
  openssl genrsa -out $DIR_KEYS/site_$1.key $4 2>/dev/null
  
  echo "Generating site CRT \"$1\""
  
  FILE=/tmp/ca_gen/site_$1.req.conf
  site_request_conf $FILE $4
  if [ "$7" != "0" ]; then append_altnames    $7 $FILE; fi
  if [ "$8" != "0" ]; then append_ip_altnames $8 $FILE; fi
  
  openssl req -new -sha256 -key $DIR_KEYS/site_$1.key -subj "$6" -out $CSR_DIR/site_$1.csr -config $FILE
  # It is possible to specify altnames the following way instead of constructing a conf file.
  # There are additional ways beyond this using new features of latest openssl as well.
  #openssl req -new -sha256 \
  #  -key keys/site_$1.key \
  #  -subj "$6" \
  #  -reqexts SAN \
  #  -config <(cat /etc/ssl/openssl.cnf \
  #   <(printf "\n[SAN]\nsubjectAltName=DNS:example.com,DNS:www.example.com")) \
  #  -out $CSR_DIR/site_$1.csr
  
  # Cleanest way to see the actual contents of the CSR to verify it was created correctly.
  #openssl req -in $CSR_DIR/site_$1.csr -text -noout
  
  # Unclean very raw way to see the contents of the CSR
  # openssl asn1parse < $CSR_DIR/site_$1.csr
  
  gen_start_end $5
  
  # Irritatingly openssl ca command does not, by default, use the altnames specified in the CSR.
  # It ignores them. They have to be re-specified. It may be pointless to specify them in the CSR as a result.
  # The altnames can be copied from the request potentially, by using the "copy_extensions = copy" option of openssl conf
  cp $DIR_CONF/ca_$2.conf $DIR_CONF/site_$1.conf
  if [ "$7" != "0" ]; then append_altnames    $7 $DIR_CONF/site_$1.conf; fi
  if [ "$8" != "0" ]; then append_ip_altnames $8 $DIR_CONF/site_$1.conf; fi
  
  openssl ca -batch \
    -config $DIR_CONF/site_$1.conf \
    -extensions req_ext \
    -out $DIR_CERTS/site_$1.crt \
    -md $3 \
    -startdate $START_DATE -enddate $END_DATE \
    -infiles $CSR_DIR/site_$1.csr
}

function create_site_crt_selfsigned() { # $1 domain, $2 message_digest, $3 rsa_bits, $4 good/expired, $5 subject, $6 altnames, $7 ipaltnames
  echo "Generating site key \"$1\""
  openssl genrsa -out $DIR_KEYS/site_$1.key $3 2>/dev/null
  
  init_root_ca dummy "/CN=US/O=US/OU=US Unit"

  FILE=/tmp/ca_gen/site_$1.req.conf
  site_request_conf $FILE $3
  if [ "$6" != "0" ]; then append_altnames    $6 $FILE; fi
  if [ "$7" != "0" ]; then append_ip_altnames $7 $FILE; fi
  
  openssl rsa -in $DIR_KEYS/site_$1.key -out $DIR_KEYS/site_rsa_$1.key
  openssl req -new -sha256 -key $DIR_KEYS/site_$1.key -subj "$5" -out $CSR_DIR/site_$1.csr -config $FILE

  cp $DIR_CONF/ca_dummy.conf $DIR_CONF/site_$1.conf
  
  # Generate an extensions file; not extending default config since x509 command doesn't have a way to specify a
  # full config file that I see.
  #echo -e "[req_ext]\nsubjectAltName = @alt_names\n" >> conf/site_$1.conf
  #echo -e "[alt_names]" >> conf/site_$1.conf
  if [ "$6" != "0" ]; then append_altnames    $6 $DIR_CONF/site_$1.conf; fi
  if [ "$7" != "0" ]; then append_ip_altnames $7 $DIR_CONF/site_$1.conf; fi
  
  gen_start_end $4
  
  #openssl x509 -req \
  #  -in $CSR_DIR/site_$1.csr \
  #  -$2 \
  #  -extensions req_ext \
  #  -out certs/site_$1.crt \
  #  -signkey keys/site_rsa_$1.key \
  #  -extfile conf/site_$1.conf
  
  openssl ca -batch \
    -config $DIR_CONF/site_$1.conf \
    -out $DIR_CERTS/site_$1.crt \
    -extensions req_ext \
    -selfsign \
    -keyfile $DIR_KEYS/site_rsa_$1.key \
    -md $2 \
    -startdate $START_DATE -enddate $END_DATE \
    -infiles $CSR_DIR/site_$1.csr
}

# Note that an altname is specified below. If req_ext is used, then this file cannot be used as is, because an empty
# alt_names section is not allowed. It is done this way so the file can be copied and a list of altnames
# be appended to the end of the copy.
function generate_conf() { # $1 ca_name
  cat >$DIR_CONF/ca_$1.conf <<EOL
[ca]
default_ca = default
[default]
certs = $DIR_CADATA/$1/
new_certs_dir = $DIR_CADATA/$1/db.certs
database = $DIR_CADATA/$1/db.index
serial = $DIR_CADATA/$1/db.serial
certificate = $DIR_CERTS/ca_$1.crt
private_key = $DIR_KEYS/ca_$1.key
default_days = 365
default_crl_days = 30
default_md = sha256
preserve = no
RANDFILE = $DIR_CADATA/$1/db.random
policy = default_policy
[default_policy]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = supplied
organizationalUnitName = supplied
commonName = supplied
emailAddress = optional
[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer
basicConstraints = critical,CA:true
[req_ext]
subjectAltName = @alt_names
[alt_names]
EOL
}

SITE_SUBJ="/ST=WA/O=Test/OU=Test Unit/CN=test.com"
SITE_ALTNAMES=test.com-blah.com
SITE_IP_ALTNAMES=127.0.0.1-13::17

init
init_root_ca    root               "/CN=US/O=US/OU=US Unit"
init_sub_ca     intermed root      "/CN=US2/O=US2/OU=US2 Unit"
init_sub_ca     intermed2 intermed "/CN=US3/O=US3/OU=US3 Unit"
create_site_crt a       intermed2 sha256 2048 good    "/CN=a$SITE_SUBJ" $SITE_ALTNAMES $SITE_IP_ALTNAMES
create_site_crt b       intermed2 sha256 2048 good    "/CN=b$SITE_SUBJ" $SITE_ALTNAMES $SITE_IP_ALTNAMES
create_site_crt weak    intermed2 sha256 1024 good    "/CN=weak$SITE_SUBJ" $SITE_ALTNAMES $SITE_IP_ALTNAMES
create_site_crt sha1    intermed2 sha1   2048 good    "/CN=sha1$SITE_SUBJ" $SITE_ALTNAMES $SITE_IP_ALTNAMES
create_site_crt expired intermed2 sha256 2048 expired "/CN=expired$SITE_SUBJ" $SITE_ALTNAMES $SITE_IP_ALTNAMES
create_site_crt badalt  intermed2 sha256 2048 expired "/CN=badalt$SITE_SUBJ" $SITE_ALTNAMES $SITE_IP_ALTNAMES

cp $DIR_CERTS/ca_root.crt external_certs/ca_root.crt
cp $DIR_CERTS/ca_intermed.crt external_certs/ca_intermed.crt
cp $DIR_CERTS/ca_intermed2.crt external_certs/ca_intermed2.crt

cp $DIR_CERTS/site_a.crt external_certs/a.crt
cp $DIR_CERTS/site_b.crt external_certs/b.crt
cp $DIR_CERTS/site_weak.crt external_certs/weak.crt
cp $DIR_CERTS/site_sha1.crt external_certs/sha1_digest.crt
cp $DIR_CERTS/site_expired.crt external_certs/expired.crt
cp $DIR_CERTS/site_badalt.crt external_certs/badalt.crt

cp $DIR_KEYS/site_a.key external_certs/a.key
cp $DIR_KEYS/site_b.key external_certs/b.key
cp $DIR_KEYS/site_weak.key external_certs/weak.key
cp $DIR_KEYS/site_sha1.key external_certs/sha1_digest.key
cp $DIR_KEYS/site_expired.key external_certs/expired.key
cp $DIR_KEYS/site_badalt.key external_certs/badalt.key

#cleanup
