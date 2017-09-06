# Minimal Redis High Availability setup

Vagrant based playground for setting up two Redis instances with 
replication, failover and correct load balancing.

Supported Redis version: `v3.x`

## setting up

```
$ vagrant up
$ vagrant ssh
$ cd /vagrant
$ ./setup.sh
```

Base configuration:
* redis on port `6379` becomes master
* redis on port `6380` becomes slave
* redis-sentinel on port `26379` will monitor master availability and perform failover
* haproxy on port `6378` becomes balancer, traffic always routed to `master` redis node
* redis data directory is `/data/redis-farm/`

> Each run of `setup.sh` script, reverts state to base configuration.

## checking setup

ensure redis on port 6379 is `master`:
```bash
$ redis-cli -p 6379 info replication | grep role
role:master
```

ensure redis on port 6380 is `slave`:
```bash
$ redis-cli -p 6380 info replication | grep role
role:slave
```

ensure `master` is accessible via haproxy:
```bash
$ redis-cli -p 6378 info replication | grep -E "role|connected_slaves"
role:master
connected_slaves:1
```

## testing failover

set our sample key:
```bash
$ redis-cli -p 6378 set hello world
OK
```

kill `master` node
```bash
redis-cli -p 6379 debug segfault
Error: Server closed the connection
```

wait for few seconds to allow sentinel perform failover.

ensure key is still accessible via haproxy:
```bash
redis-cli -p 6378 get hello
"world"
```

checking haproxy is poining to `master` node:
```bash
$ redis-cli -p 6378 set hello "cruel world"
OK
```

checking redis role on port 6380:
```bash
$ redis-cli -p 6380 info replication | grep role
role:master
```

## return failed redis node back

start failed redis node:
```bash
$ sudo systemctl start redis-6379
```

check redis role on port 6379:
```bash
$ redis-cli -p 6379 info replication | grep role
role:slave
```
