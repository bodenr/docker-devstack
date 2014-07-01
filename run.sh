#!/bin/bash

set -e

CONF_VOL=/usr/local/devstack
STACK_DIR=/home/stack/devstack
WAIT_PIPE=/tmp/devstackp
RESET=${RESET:0}

# consumers can set NON_STANDARD_REQS for unmatched global deps.
# see https://github.com/openstack/requirements/blob/master/update.py#L154
if [ "$NON_STANDARD_REQS" == "" ]; then
	echo "Exporting NON_STANDARD_REQS..."
	export NON_STANDARD_REQS=1
fi

if [ $RESET -ne 0 ]; then
	echo "Resetting devstack install dirs..."
	rm -rf /opt/stack
	rm -rf $STACK_DIR
fi

if [ ! -d $STACK_DIR ]; then
	echo "Cloning devstack..."
	su -c 'cd /home/stack && git clone https://github.com/openstack-dev/devstack.git' stack
	# hack around lxc kernel bug: https://bugs.launchpad.net/ubuntu/+source/lxc/+bug/1279041
	sed -i '/sudo sysctl -w net.ipv4.ip_local_reserved_ports/ s/^/echo # /' $STACK_DIR/tools/fixup_stuff.sh
	# remove sysctl calls due to ro fs in container
	sed -i '/sudo sysctl -w net.ipv4.ip_forward/ s/^/echo # /' $STACK_DIR/lib/nova
	sed -i '/sudo sysctl -w net.ipv4.ip_forward/ s/^/echo # /' $STACK_DIR/stack.sh

	# apt-get does not autostart bins, so hack around
	sed -i '/sudo rabbitmqctl change_password/ s/^/restart_service rabbitmq-server \&\& /' $STACK_DIR/lib/rpc_backend
	sed -i '/sudo mysql -uroot/istart_service $MYSQL' $STACK_DIR/lib/databases/mysql
fi

if [ ! -f $STACK_DIR/local.conf ]; then
	# setup local.conf
	if [ -f $CONF_VOL/local.yaml ]; then
		echo "Generating local.conf from yaml..."
		cat $CONF_VOL/local.yaml | /y2l > $STACK_DIR/local.conf
	elif [ -f $CONF_VOL/local.conf ]; then
		echo "Copying user defined local.conf..."
		cp $CONF_VOL/local.conf $STACK_DIR/
	else
		echo "Copying sample local.conf..."
		cp $STACK_DIR/samples/local.conf $STACK_DIR/
	fi
fi

# run devstack
su -c "cd $STACK_DIR && ./stack.sh" stack

# trap docker stop signal
trap 'echo Stopping container;kill $(jobs -p)' TERM
mkfifo $WAIT_PIPE
read < $WAIT_PIPE &
wait
rm $WAIT_PIPE
su -c "cd $STACK_DIR && ./unstack.sh" stack	
