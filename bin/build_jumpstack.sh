#!/bin/bash

# simple script to build a devstack enabled image which
# also includes jumpgate

BLD_DIR=/tmp/bld

mkdir $BLD_DIR && cp -r ../* $BLD_DIR && pushd $BLD_DIR
sed -i 's|FROM dockerfile/ubuntu|FROM bodenr/docker-jumpgate|' $BLD_DIR/Dockerfile
docker build -t jumpstack .
popd
rm -rf $BLD_DIR
