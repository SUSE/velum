#!/bin/bash

# This script re-generates all of the keys and certs within the external_certs directory.
# The files there are used by the spec/features/settings/external_cert_feature_spec test

init() {
  ROOT_DIR=$( mktemp -d )
  CSR_DIR=$ROOT_DIR/csr
  DIR_CERTS=$ROOT_DIR/certs
  DIR_CONF=$ROOT_DIR/conf
  DIR_KEYS=$ROOT_DIR/keys
  DIR_CADATA=$ROOT_DIR/cadata
  
  mkdir -vp $CSR_DIR
  mkdir -vp $DIR_CERTS
  mkdir -vp $DIR_CONF
  mkdir -vp $DIR_KEYS
  mkdir -vp $DIR_CADATA
}

cleanup() {
  rm -vrf $ROOT_DIR
}

init_ca() { # $1 ca_name
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

init_root_ca() { # $1 ca_name, $2 subject
  init_ca $1
  echo "Generating CRT \"$1\""
  openssl req -new -x509 -days 100 -extensions v3_ca -key $DIR_KEYS/ca_$1.key -out $DIR_CERTS/ca_$1.crt -subj "$2"
}

init_sub_ca() { # $1 ca_name, $2 parent_ca, $3 subject
  init_ca $1
  echo "Generating CRT \"$1\""
  openssl req -sha256 -new \
    -key  $DIR_KEYS/ca_$1.key \
    -out  $CSR_DIR/ca_$1.csr \
    -subj "$3"
  
  openssl ca -batch \
    -config     $DIR_CONF/ca_$2.conf \
    -extensions v3_ca \
    -out        $DIR_CERTS/ca_$1.crt \
    -infiles    $CSR_DIR/ca_$1.csr 2>/dev/null
}

append_altnames() { # $1 altnames, $2 filename
  # Split up dash delimited string into array
  IFS='-' read -r -a altnames <<< "$1"
  for index in "${!altnames[@]}"
  do
    echo "DNS.$(($index+1)) = ${altnames[index]}"
  done >> $2
}

append_ip_altnames() { # $1 altnames, $2 filename
  # Split up dash delimited string into array
  IFS='-' read -r -a altnames <<< "$1"
  for index in "${!altnames[@]}"
  do
    echo "IP.$(($index+1)) = ${altnames[index]}"
  done >> $2
}

site_request_conf() { # $1 file, $2 bits
  {
    echo "[req]"
    echo default_bits = $2
    echo distinguished_name = req_distinguished_name
    echo req_extensions = req_ext
  
    # Various prompts for the portions of the subject would go here, as well as defaults.
    # They can, though, be left blank when the subject is provided on the command line.
    echo "[req_distinguished_name]"

    # Extension for "no extensions" populated with a default setting so that it works
    echo -e "[no_ext]\nsubjectKeyIdentifier = hash\n"
    
    echo -e "[req_ext]\nsubjectAltName = @alt_names\n"
    echo -e "[alt_names]"
  } > $1
}

gen_start_end() { # $1 good/expired
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

parse_args() {
  declare -n a=$1
  shift
  while [[ -n $1 ]]; do
    a[${1%%=*}]=${1#*=}
    shift
  done
}

create_site_crt() {
  declare -A args=(
    [message_digest]=sha256
    [rsa_bits]=2048
    [date]=good     # can be "good" or "expired"
    [alts]=0    # dash delimited altnames
    [ip_alts]=0 # dash delimited ip addresses ( ipv4 or ipv6 )
  )
  # domain  - filename for certificate
  # ca      - name of CA to use
  # subject - subject name in ldap format ( CN=blah,OU=test etc )
  parse_args args "$@"

  echo "Generating site key \"${args[domain]}\""
  openssl genrsa \
    -out $DIR_KEYS/site_${args[domain]}.key \
    ${args[rsa_bits]} \
    2>/dev/null
  
  echo "Generating site CRT \"${args[domain]}\""
  
  FILE=$ROOT_DIR/site_${args[domain]}.req.conf
  site_request_conf $FILE ${args[rsa_bits]}
  if [ "${args[alts]}"    != "0" ]; then append_altnames    ${args[alts]}    $FILE; fi
  if [ "${args[ip_alts]}" != "0" ]; then append_ip_altnames ${args[ip_alts]} $FILE; fi
  
  EXTS=req_ext
  if [ "${args[alts]}" == "0" ] && [ "${args[ip_alts]}" == "0" ]; then EXTS=no_ext; fi
  echo EXTS=$EXTS
  
  openssl req -new \
    -sha256 \
    -reqexts $EXTS \
    -key     $DIR_KEYS/site_${args[domain]}.key \
    -subj    "${args[subject]}" \
    -out     $CSR_DIR/site_${args[domain]}.csr \
    -config  $FILE
  
  # Easy way to see contents of the CSR for debugging
  #openssl req -in $CSR_DIR/site_$1.csr -text -noout
  
  gen_start_end ${args[date]}
  
  # Irritatingly openssl ca command does not, by default, use the altnames specified in the CSR.
  # It ignores them. They have to be re-specified. It may be pointless to specify them in the CSR as a result.
  # The altnames can be copied from the request potentially, by using the "copy_extensions = copy" option of openssl conf
  cp $DIR_CONF/ca_${args[ca]}.conf $DIR_CONF/site_${args[domain]}.conf
  if [ "${args[alts]}"    != "0" ]; then append_altnames    ${args[alts]}    $DIR_CONF/site_${args[domain]}.conf; fi
  if [ "${args[ip_alts]}" != "0" ]; then append_ip_altnames ${args[ip_alts]} $DIR_CONF/site_${args[domain]}.conf; fi
  
  openssl ca -batch \
    -config     $DIR_CONF/site_${args[domain]}.conf \
    -extensions $EXTS \
    -out        $DIR_CERTS/site_${args[domain]}.crt \
    -md         ${args[message_digest]} \
    -startdate  $START_DATE -enddate $END_DATE \
    -infiles    $CSR_DIR/site_${args[domain]}.csr
}

create_site_crt_selfsigned() {
  declare -A args=(
    [message_digest]=sha256
    [rsa_bits]=2048
    [date]=good # can be "good" or "expired"
    [alts]=0    # dash delimited altnames
    [ip_alts]=0 # dash delimited ip addresses ( ipv4 or ipv6 )
  )
  # domain  - filename for certificate
  # ca      - name of CA to use
  # subject - subject name in ldap format ( CN=blah,OU=test etc )
  parse_args args "$@"
  
  echo "Generating site key \"${args[domain]}\""
  openssl genrsa \
    -out $DIR_KEYS/site_${args[domain]}.key \
    ${args[rsa_bits]} \
    2>/dev/null
  
  init_root_ca dummy "/CN=US/O=US/OU=US Unit"

  FILE=/tmp/ca_gen/site_${args[domain]}.req.conf
  site_request_conf $FILE ${args[rsa_bits]}
  if [ "${args[alts]}"    != "0" ]; then append_altnames    ${args[alts]}    $FILE; fi
  if [ "${args[ip_alts]}" != "0" ]; then append_ip_altnames ${args[ip_alts]} $FILE; fi

  openssl rsa \
    -in  $DIR_KEYS/site_${args[domain]}.key \
    -out $DIR_KEYS/site_rsa_${args[domain]}.key
  
  openssl req -new -sha256 \
    -key    $DIR_KEYS/site_$1.key \
    -subj   "${args[subject]}" \
    -out    $CSR_DIR/site_${args[domain]}.csr \
    -config $FILE

  cp $DIR_CONF/ca_dummy.conf $DIR_CONF/site_${args[domain]}.conf
  
  # Append the altnames to the configuration file
  if [ "${args[alts]}"    != "0" ]; then append_altnames    ${args[alts]}    $DIR_CONF/site_${args[domain]}.conf; fi
  if [ "${args[ip_alts]}" != "0" ]; then append_ip_altnames ${args[ip_alts]} $DIR_CONF/site_${args[domain]}.conf; fi
  
  gen_start_end ${args[date]}
  
  openssl ca -batch \
    -config     $DIR_CONF/site_${args[domain]}.conf \
    -out        $DIR_CERTS/site_${args[domain]}.crt \
    -extensions req_ext \
    -selfsign   \
    -keyfile    $DIR_KEYS/site_rsa_${args[domain]}.key \
    -md         ${args[message_digest]} \
    -startdate  $START_DATE -enddate $END_DATE \
    -infiles    $CSR_DIR/site_${args[domain]}.csr
}

joined_lines() {
  declare -n return=$1
  readarray -t lines
  local IFS=-
  return="${lines[*]}"
}

# Note that altname extension is specified below. If req_ext is used, then this file cannot be used as is, because an empty
# alt_names section is not allowed. It is done this way so the file can be copied and a list of altnames
# be appended to the end of the copy.
generate_conf() { # $1 ca_name
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
joined_lines "ALTS_VELUM" << EOM
admin.devenv.caasp.suse.net
admin
admin.infra.caasp.local
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.infra.caasp.local
testdomain.com
EOM
IP_ALTS_VELUM=10.17.1.0

# Read multiline block into variable
joined_lines "ALTS_KUBEAPI" << EOM
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
IP_ALTS_KUBEAPI=172.24.0.1

# Read multiline block into variable
joined_lines "ALTS_DEX" << EOM
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
IP_ALTS_DEX=172.24.0.1

SUBJ="/ST=WA/O=Test/OU=Test Unit/CN=test.com"
ALTS_BAD=test.com-blah.com
IP_ALTS_BAD=127.0.0.1-13::17

init
init_root_ca    root                 "/CN=US/O=US/OU=US Unit"
init_sub_ca     intermed    root     "/CN=US2/O=US2/OU=US2 Unit"
init_sub_ca     intermed2   intermed "/CN=US3/O=US3/OU=US3 Unit"

ca=ca=intermed2

create_site_crt domain=velum_a     $ca subject="/CN=va$SUBJ"      alts=$ALTS_VELUM   ip_alts=$IP_ALTS_VELUM
create_site_crt domain=velum_b     $ca subject="/CN=vb$SUBJ"      alts=$ALTS_VELUM   ip_alts=$IP_ALTS_VELUM
create_site_crt domain=kubeapi_a   $ca subject="/CN=ka$SUBJ"      alts=$ALTS_KUBEAPI ip_alts=$IP_ALTS_KUBEAPI
create_site_crt domain=kubeapi_b   $ca subject="/CN=kb$SUBJ"      alts=$ALTS_KUBEAPI ip_alts=$IP_ALTS_KUBEAPI
create_site_crt domain=dex_a       $ca subject="/CN=da$SUBJ"      alts=$ALTS_DEX     ip_alts=$IP_ALTS_DEX
create_site_crt domain=dex_b       $ca subject="/CN=db$SUBJ"      alts=$ALTS_DEX     ip_alts=$IP_ALTS_DEX 
create_site_crt domain=weak        $ca subject="/CN=weak$SUBJ"    alts=$ALTS_VELUM   ip_alts=$IP_ALTS_VELUM \
  rsa_bits=1024
create_site_crt domain=sha1_digest $ca subject="/CN=sha1$SUBJ"    alts=$ALTS_VELUM   ip_alts=$IP_ALTS_VELUM \
  message_digest=sha1
create_site_crt domain=expired     $ca subject="/CN=expired$SUBJ" alts=$ALTS_VELUM   ip_alts=$IP_ALTS_VELUM \
  date=expired
create_site_crt domain=badalt      $ca subject="/CN=badalt$SUBJ"  alts=$ALTS_BAD     ip_alts=$IP_ALTS_BAD
create_site_crt domain=noalt       $ca subject="/CN=noalt$SUBJ"

for cert in $DIR_CERTS/ca_*.crt; do
  mv -v "$cert" "external_certs/$(basename "$cert")"
done

for cert in $DIR_CERTS/site_*.crt; do
  BASE=$(basename "$cert")
  BASE=$(echo $BASE|sed -r "s/site_//")
  mv -v "$cert" "external_certs/$BASE"
done

for key in $DIR_KEYS/site_*.key; do
  BASE=$(basename "$key")
  BASE=$(echo $BASE|sed -r "s/site_//")
  mv "$key" "external_certs/$BASE"
done

cleanup
