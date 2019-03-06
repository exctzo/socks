#!/usr/bin/env bash

echo "* Downloading dante-server..."
wget http://ppa.launchpad.net/dajhorn/dante/ubuntu/pool/main/d/dante/dante-server_1.4.1-1_amd64.deb > /dev/null 2>&1
echo "* Installing dante-server..."
apt-get install gdebi-core -y > /dev/null 2>&1
gdebi dante-server_1.4.1-1_amd64.deb
echo "* Adjusting the Dante Configuration..."
rm /etc/danted.conf
cp ~/shsyea/configs/danted.conf /etc/danted.conf

echo "* Creating user for connect to proxy..."
read -p 'Username: ' uservar
useradd --shell /usr/sbin/nologin $uservar
passwd $uservar

echo "* Adding rule to firewall..."
ufw allow 1080/tcp

echo "* Restarting dant service..."
service danted restart
