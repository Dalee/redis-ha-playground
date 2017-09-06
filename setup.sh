#!/usr/bin/env bash

#
# install required software
#
echo "==> Installing software (if needed, may take few minutes)..."
sudo apt-get -qq update
sudo apt-get -qq -y install \
    haproxy \
    redis-server \
    redis-tools

#
# disable default redis.service
# stop running cluster (if exists)
#
echo "==> Stopping Redis-HA..."
sudo systemctl stop redis 2>/dev/null && sudo systemctl disable redis 2>/dev/null
sudo systemctl stop redis-sentinel haproxy redis-6379 redis-6380 2>/dev/null

#
# setting up redis high availability cluster:
#
# - setup configuration files
# - drop redis databases
# - remove logs
# - install sentinel
# - install haproxy config
#
echo "==> Setting up Redis-HA..."
sudo mkdir -p /data/redis-farm

sudo cp -f /vagrant/redis-6379.service /etc/systemd/system/redis-6379.service
sudo cp -f /vagrant/redis-6380.service /etc/systemd/system/redis-6380.service
sudo cp -f /vagrant/redis-sentinel.service /etc/systemd/system/redis-sentinel.service
sudo systemctl daemon-reload

sudo cp -f /vagrant/redis-6379.conf /data/redis-farm/redis-6379.conf
sudo cp -f /vagrant/redis-6380.conf /data/redis-farm/redis-6380.conf
sudo cp -f /vagrant/redis-sentinel.conf /data/redis-farm/redis-sentinel.conf

sudo chown -R vagrant:vagrant /data/redis-farm
sudo rm -rf /data/redis-farm/*.rdb
sudo rm -rf /data/redis-farm/*.log

sudo mkdir -p /data/haproxy
sudo cp -f /vagrant/haproxy.conf /etc/haproxy/haproxy.cfg

#
# starting up cluster
#
echo "==> Starting Redis-HA..."
sudo systemctl start redis-6379
sudo systemctl start redis-6380
sudo systemctl start redis-sentinel
sudo systemctl start haproxy

echo "==> Done!"
