#!/bin/bash

set -e
shopt -s extglob

datacenter=dc1
domain=consul

usage() {
  cat <<EOF
usage: $0 option

OPTIONS:
   help       Show this message
   clean      Clean up
   generate   Generate a consul SSL data bag item
EOF
}

mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

clean() {
  rm -rf agent
  cd consul_ca
  rm -rf !(openssl.cnf)
}

pre_clean() {
  cd $mydir
  rm -f agent/req.pem
  if [ -d consul_ca ]; then
    cd consul_ca
    rm -rf !(openssl.cnf|cakey.pem|cacert.*)
  fi
}

copy_certs() {
  cd $mydir
  mkdir -p certs
  cp consul_ca/cacert.pem certs/cacert.crt
  cp agent/key.pem certs/consul.key
  cp agent/cert.pem certs/consul.crt
}

generate() {
  mkdir -p agent consul_ca/certs
  touch consul_ca/index.txt
  echo 01 > consul_ca/serial
  cd consul_ca
  openssl req -x509 -config openssl.cnf -newkey rsa:2048 -days 3650 -out cacert.pem -outform PEM -subj /CN=ConsulCA/ -nodes
  cd ../agent
  openssl genrsa -out key.pem 2048
  openssl req -new -key key.pem -out req.pem -outform PEM -subj /CN=server.${datacenter}.${domain}/O=server/ -nodes
  cd ../consul_ca
  openssl ca -config openssl.cnf -in ../agent/req.pem -out ../agent/cert.pem -notext -batch -extensions agent_ca_extensions
}

cd $mydir

if [ "$1" = "generate" ]; then
  echo "Generating a consul SSL data bag item ..."
  generate
  copy_certs
  pre_clean
elif [ "$1" = "clean" ]; then
  echo "Cleaning up ..."
  clean
else
  usage
fi
