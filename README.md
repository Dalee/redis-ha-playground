# Minimal Redis 3.x High Availability setup

Vagrant based playground for setting up two Redis instances with 
replication, failover and correct load balancing.

## setting up

```
$ vagrant up
$ vagrant ssh
$ /vagrant/setup.sh
```

Initial configuration:
* redis on port `6379` is `master`
* redis on port `6380` is `slave`
* redis-sentinel on port `26379` is failover arbiter
* haproxy on port `6378` is redis balancer

> Each run of `setup.sh` script, reverts state to initial configuration.

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
$ redis-cli -p 6378 info | grep -E "role|connected_slaves|config_file"
config_file:/data/redis-farm/redis-6379.conf
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
