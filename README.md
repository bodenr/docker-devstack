docker-devstack
===============

Generic docker container to run devstack services - currently
a PoC / toy and not ready for anything useful.

The idea is to provide a generic docker container
which can be used to run 1 or more specific OpenStack
services installed via devstack in the container.


Building the image
-----------

```
docker build -t devstack .
```


Yaml to devstack local conf
-----------

To simplify the creation of devstack's ```local.conf```
this image contains a simple 'yaml to local conf' filter
which is capable of taking a yaml file as input and spitting
out a devstack ```local.conf``` as output.

See the sample [local.yaml](samples/local.yaml)


Running the image
-----------

Right now the init command in the container expects a
```local.conf``` or ```local.yaml``` to be make available
under ```/usr/local/devstack/``` when starting the container.
It will look for ```local.yaml``` or ```local.conf``` and if
a yaml is found convert and write it to ```/home/stack/devstack```
in the container; if ```local.conf``` is found it just copies it.

This allows you to bind mount your devstack local conf / yaml
into the container to conf devstack.

The init script also supports an env var called ```RESET``` which
when set (to anything) will clean up the previous devstack install
including deleting the git dirs before re stacking.

Example useage:

* Create a ```local.conf``` or ```local.yaml``` on your host system
which will drive the containerized devstack.

* Run the container bind mounting your conf or yaml:

```
docker run -d --privileged=true -v ~/devstack/local.yaml:/usr/local/devstack devstack
```

Note that ```--privileged=true``` is needed by some services to perform
```iptables``` and related commands which require Linux capabilities.

