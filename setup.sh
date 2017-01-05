#!/bin/bash

set -e

# $1 - username
# $2 - password
function add_user() {
	echo "creating user: ${1}"
	if ! id -u "$1" >/dev/null 2>&1; then
	    echo "Adding $1 user"
	    useradd -G root -m "$1" -s /bin/bash
	    passwd "$1" <<_EOF_
"$2"
"$2"
_EOF_
	fi
}


# apt-get install packages
apt-get update
apt-get install -y gcc git python-pip python-dev sudo libyaml-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev wget
apt-get install -y libmysqlclient-dev
apt-get install -y python-mysqldb
# apt-get pulls in an old incompatible version of six which
# causes problems w/some services.. hack around that by
# getting a later version of six
wget http://launchpadlibrarian.net/173867243/python-six_1.6.1-1_all.deb
dpkg -i ./python-six_1.6.1-1_all.deb
pip install PyYaml


# prep for devstack
STACK_PASSWORD=`date +%s | sha256sum | base64 | head -c 10 ; echo`
add_user stack ${STACK_PASSWORD}
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
