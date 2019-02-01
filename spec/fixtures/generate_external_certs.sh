#!/bin/bash

# This script re-generates all of the keys and certs within the external_certs directory.
# The files there are used by the spec/features/settings/external_cert_feature_spec test

function init() {
  ROOT_DIR=/tmp/ca_gen
  CSR_DIR=$ROOT_DIR/csr
  DIR_CERTS=$ROOT_DIR/certs
  DIR_CONF=$ROOT_DIR/conf
  DIR_KEYS=$ROOT_DIR/keys
  DIR_CADATA=$ROOT_DIR/cadata
  
  mkdir -p $CSR_DIR
  mkdir -p $DIR_CERTS
  mkdir -p $DIR_CONF
  mkdir -p $DIR_KEYS
  mkdir -p $DIR_CADATA
}

function cleanup() {
  rm -rf $ROOT_DIR
}

function init_ca() { # $1 ca_name
  echo "Initiating CA  \"$1\""
  generate_conf $1
  # Create / clear certs directory for CA
  mkdir -p $DIR_CADATA/$1/db.certs
  rm $DIR_CADATA/$1/db.certs/* 2>/dev/null
  
  # Delete both db.index and db.index.attr if they exist
  rm $DIR_CADATA/$1/db.inde* 2>/dev/null
  
  # Create blank db.index to start off CA empty
  touch $DIR_CADATA/$1/db.index

  # Create db.index.attr with default contents
  echo unique_subject = yes > $DIR_CADATA/$1/db.index.attr

  # Serial can start at 1 because serials are unique per CA
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
  # Split up dash delimited string into array
  IFS='-' read -r -a altnames <<< "$1"
  for index in "${!altnames[@]}"
  do
      echo "DNS.$(($index+1)) = ${altnames[index]}" >> $2
  done
}

function append_ip_altnames() { # $1 altnames, $2 filename
  # Split up dash delimited string into array
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
  
  echo -e "[no_ext]\nsubjectKeyIdentifier = hash\n" >> $1
  echo -e "[req_ext]\nsubjectAltName = @alt_names\n" >> $1
  echo -e "[alt_names]" >> $1
}

function gen_start_end() { # $1 good/expired
  # Right now we are just using hardcoded good/bad for the date range validity.
  # For most purposes it would be better to expose the clean text specification
  # of both start and end as parameters.
  if [ $1 = "good" ]
  then
    START_DATE=$(TZ=UTC date +"%Y%m%d%H%M%SZ" -d "-1 day")
    END_DATE=$(TZ=UTC date +"%Y%m%d%H%M%SZ" -d "+5 years")
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
  
  EXTS=req_ext
  if [ "$7" == "0" ] && [ "$8" == "0" ]; then EXTS=no_ext; fi
  echo EXTS=$EXTS
  
  openssl req -new \
    -sha256 \
    -reqexts $EXTS \
    -key $DIR_KEYS/site_$1.key \
    -subj "$6" \
    -out $CSR_DIR/site_$1.csr \
    -config $FILE
  
  # Easy way to see contents of the CSR for debugging
  #openssl req -in $CSR_DIR/site_$1.csr -text -noout
  
  gen_start_end $5
  
  # Irritatingly openssl ca command does not, by default, use the altnames specified in the CSR.
  # It ignores them. They have to be re-specified. It may be pointless to specify them in the CSR as a result.
  # The altnames can be copied from the request potentially, by using the "copy_extensions = copy" option of openssl conf
  cp $DIR_CONF/ca_$2.conf $DIR_CONF/site_$1.conf
  if [ "$7" != "0" ]; then append_altnames    $7 $DIR_CONF/site_$1.conf; fi
  if [ "$8" != "0" ]; then append_ip_altnames $8 $DIR_CONF/site_$1.conf; fi
  
  openssl ca -batch \
    -config $DIR_CONF/site_$1.conf \
    -extensions $EXTS \
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
  
  # Append the altnames to the configuration file
  if [ "$6" != "0" ]; then append_altnames    $6 $DIR_CONF/site_$1.conf; fi
  if [ "$7" != "0" ]; then append_ip_altnames $7 $DIR_CONF/site_$1.conf; fi
  
  gen_start_end $4
  
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
  cat >$DIR_CONF/ca_$1.conf << EOL
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
[no_ext]
subjectKeyIdentifier = hash
[req_ext]
subjectAltName = @alt_names
[alt_names]
EOL
}

# Read multiline block into variable
read -r -d '' ALTNAMES_VELUM_LN << EOM
admin.devenv.caasp.suse.net
admin
admin.infra.caasp.local
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.infra.caasp.local
testdomain.com
EOM
IP_ALTNAMES_VELUM=10.17.1.0

# Read multiline block into variable
read -r -d '' ALTNAMES_KUBEAPI_LN << EOM
kubernetes
kubernetes.default
kubernetes.default.svc
kubernetes.default.svc.cluster.local
api
api.infra.caasp.local
kube-api-x1.devenv.caasp.suse.net
master-0
master-0.infra.caasp.local
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.infra.caasp.local
EOM
IP_ALTNAMES_KUBEAPI=172.24.0.1

# Read multiline block into variable
read -r -d '' ALTNAMES_DEX_LN << EOM
dex
dex.kube-system
dex.kube-system.svc
dex.kube-system.svc.infra.caasp.local
dex.kube-system.svc.cluster.local
kubernetes
kubernetes.default
kubernetes.default.svc
api
api.infra.caasp.local
kube-api-x1.devenv.caasp.suse.net
master-0
master-0.infra.caasp.local
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb.infra.caasp.local
EOM
IP_ALTNAMES_DEX=172.24.0.1

ALTNAMES_VELUM=$(echo "$ALTNAMES_VELUM_LN" | tr "\n" -)
ALTNAMES_KUBEAPI=$(echo "$ALTNAMES_KUBEAPI_LN" | tr "\n" -)
ALTNAMES_DEX=$(echo "$ALTNAMES_DEX_LN" | tr "\n" -)

# Strip extra dashes at end of line
ALTNAMES_VELUM="${ALTNAMES_VELUM%?}"
ALTNAMES_KUBEAPI="${ALTNAMES_KUBEAPI%?}"
ALTNAMES_DEX="${ALTNAMES_DEX%?}"

SITE_SUBJ="/ST=WA/O=Test/OU=Test Unit/CN=test.com"
ALTNAMES_BAD=test.com-blah.com
IP_ALTNAMES_BAD=127.0.0.1-13::17

init
init_root_ca    root                 "/CN=US/O=US/OU=US Unit"
init_sub_ca     intermed    root     "/CN=US2/O=US2/OU=US2 Unit"
init_sub_ca     intermed2   intermed "/CN=US3/O=US3/OU=US3 Unit"
create_site_crt velum_a     intermed2 sha256 2048 good    "/CN=va$SITE_SUBJ"      $ALTNAMES_VELUM   $IP_ALTNAMES_VELUM
create_site_crt velum_b     intermed2 sha256 2048 good    "/CN=vb$SITE_SUBJ"      $ALTNAMES_VELUM   $IP_ALTNAMES_VELUM
create_site_crt kubeapi_a   intermed2 sha256 2048 good    "/CN=ka$SITE_SUBJ"      $ALTNAMES_KUBEAPI $IP_ALTNAMES_KUBEAPI
create_site_crt kubeapi_b   intermed2 sha256 2048 good    "/CN=kb$SITE_SUBJ"      $ALTNAMES_KUBEAPI $IP_ALTNAMES_KUBEAPI
create_site_crt dex_a       intermed2 sha256 2048 good    "/CN=da$SITE_SUBJ"      $ALTNAMES_DEX     $IP_ALTNAMES_DEX
create_site_crt dex_b       intermed2 sha256 2048 good    "/CN=db$SITE_SUBJ"      $ALTNAMES_DEX     $IP_ALTNAMES_DEX 
create_site_crt weak        intermed2 sha256 1024 good    "/CN=weak$SITE_SUBJ"    $ALTNAMES_VELUM   $IP_ALTNAMES_VELUM
create_site_crt sha1_digest intermed2 sha1   2048 good    "/CN=sha1$SITE_SUBJ"    $ALTNAMES_VELUM   $IP_ALTNAMES_VELUM
create_site_crt expired     intermed2 sha256 2048 expired "/CN=expired$SITE_SUBJ" $ALTNAMES_VELUM   $IP_ALTNAMES_VELUM
create_site_crt badalt      intermed2 sha256 2048 good    "/CN=badalt$SITE_SUBJ"  $ALTNAMES_BAD     $IP_ALTNAMES_BAD
create_site_crt noalt       intermed2 sha256 2048 good    "/CN=noalt$SITE_SUBJ"   0                 0

for cert in $DIR_CERTS/ca_*.crt; do
  mv "$cert" "external_certs/$(basename "$cert")"
done

for cert in $DIR_CERTS/site_*.crt; do
  BASE=$(basename "$cert")
  BASE=$(echo $BASE|sed -r "s/site_//")
  mv "$cert" "external_certs/$BASE"
done

for key in $DIR_KEYS/site_*.key; do
  BASE=$(basename "$key")
  BASE=$(echo $BASE|sed -r "s/site_//")
  mv "$key" "external_certs/$BASE"
done

cleanup
