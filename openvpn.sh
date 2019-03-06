#!/usr/bin/env bash

echo "* Setting firewall..."
ufw allow OpenSSH
ufw enable
ufw status

echo "* Installing openvpn..."
apt-get update -y > /dev/null 2>&1
apt-get install openvpn easy-rsa -y > /dev/null 2>&1

echo "* Tunning the CA Directory..."
make-cadir ~/openvpn-ca
cd ~/openvpn-ca/

echo "* Configuring the CA Variables..."
sed -i -e 's/export KEY_PROVINCE="CA"/export KEY_PROVINCE="NY"/g' vars
sed -i -e 's/export KEY_CITY="SanFrancisco"/export KEY_CITY="New York City"/g' vars
sed -i -e 's/export KEY_ORG="Fort-Funston"/export KEY_ORG="shsyea"/g' vars
sed -i -e 's/export KEY_EMAIL="me@myhost.mydomain"/export KEY_EMAIL="admin@shsyea.com"/g' vars
sed -i -e 's/export KEY_OU="MyOrganizationalUnit"/export KEY_OU="Community"/g' vars
sed -i -e 's/export KEY_NAME="EasyRSA"/export KEY_NAME="server"/g' vars

echo "* Building the Certificate Authority..."
source vars
./clean-all
./build-ca

echo "* Creating the Server Certificate, Key, and Encryption Files..."
./build-key-server server
./build-dh
openvpn --genkey --secret keys/ta.key

echo "* Generating a Client Certificate and Key Pair..."
source vars
./build-key testclient

echo "* Configuring the OpenVPN Service..."
cd ~/openvpn-ca/keys
sudo cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf > /dev/null 2>&1

echo "* Adjusting the OpenVPN Configuration..."
sed -i -e 's/;tls-auth ta.key 0/tls-auth ta.key 0/g' /etc/openvpn/server.conf
sed -i '244 a key-direction 0' /etc/openvpn/server.conf
sed -i -e 's/;cipher AES-128-CBC/cipher AES-128-CBC/g' /etc/openvpn/server.conf
sed -i '251 a auth SHA256' /etc/openvpn/server.conf
sed -i -e 's/;user nobody/user nobody/g' /etc/openvpn/server.conf
sed -i -e 's/;group nogroup/group nogroup/g' /etc/openvpn/server.conf
sed -i -e 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/g' /etc/openvpn/server.conf
sed -i -e 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 208.67.222.222"/g' /etc/openvpn/server.conf
sed -i -e 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 208.67.220.220"/g' /etc/openvpn/server.conf
sed -i -e 's/port 1194/port 443/g' /etc/openvpn/server.conf
sed -i -e 's/;proto tcp/proto tcp/g' /etc/openvpn/server.conf
sed -i -e 's/proto udp/;proto udp/g' /etc/openvpn/server.conf

echo "* Adjusting the Server Networking Configuration..."
sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p

sed -i '9 a # END OPENVPN RULES' /etc/ufw/before.rules
sed -i '9 a COMMIT' /etc/ufw/before.rules
sed -i '9 a -A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE' /etc/ufw/before.rules
sed -i '9 a # Allow traffic from OpenVPN client to eth0' /etc/ufw/before.rules
sed -i '9 a :POSTROUTING ACCEPT [0:0]' /etc/ufw/before.rules
sed -i '9 a *nat' /etc/ufw/before.rules
sed -i '9 a # NAT table rules' /etc/ufw/before.rules
sed -i '9 a # START OPENVPN RULES' /etc/ufw/before.rules

sed -i -e 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

sudo ufw allow 443/tcp
sudo ufw disable
sudo ufw enable

echo "* Starting and Enable the OpenVPN Service..."
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server

echo "* Creating Client Configuration Infrastructure..."
mkdir -p ~/client-configs/files
chmod 700 ~/client-configs/files

cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
ipaddr=$(hostname  -I | cut -f1 -d' ')
sed -i -e 's/remote my-server-1 1194/remote '$ipaddr' 443/g' ~/client-configs/base.conf
sed -i -e 's/;proto tcp/proto tcp/g' ~/client-configs/base.conf
sed -i -e 's/proto udp/;proto udp/g' ~/client-configs/base.conf
sed -i -e 's/;user nobody/user nobody/g' ~/client-configs/base.conf
sed -i -e 's/;group nogroup/group nogroup/g' ~/client-configs/base.conf
sed -i -e 's/ca ca.crt/#ca ca.crt/g' ~/client-configs/base.conf
sed -i -e 's/cert client.crt/#cert client.crt/g' ~/client-configs/base.conf
sed -i -e 's/key client.key/#key client.key/g' ~/client-configs/base.conf
sed -i -e 's/;cipher x/cipher AES-128-CBC/g' ~/client-configs/base.conf
sed -i '113 a auth SHA256' ~/client-configs/base.conf
sed -i '114 a key-direction 1' ~/client-configs/base.conf
sed -i '$ a #' ~/client-configs/base.conf
sed -i '$ a # script-security 2' ~/client-configs/base.conf
sed -i '$ a # up /etc/openvpn/update-resolv-conf' ~/client-configs/base.conf
sed -i '$ a # down /etc/openvpn/update-resolv-conf' ~/client-configs/base.conf

cp ~/shsyea/configs/make_config.sh ~/client-configs/
chmod 700 ~/client-configs/make_config.sh

echo "* Generating Client Configurations..."
cd ~/client-configs
./make_config.sh testclient

echo "* Generating Client Profiles..."
echo "How many profiles do you want to create?"
read COUNTER
echo "Do you want to create a password-protected (1) set of credentials, or not (0)?"
read SECUR
until [  $COUNTER -lt 1 ]; do
             cd ~/openvpn-ca
             source vars
             read -p 'Username: ' uservar
             if [ $SECUR -eq 1 ]
             then
               ./build-key-pass $uservar
             else
               ./build-key $uservar
             fi
             cd ~/client-configs
             ./make_config.sh $uservar
             let COUNTER-=1
         done
