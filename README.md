# OpenVPN and SOCKS5 Proxy on VPS
## Installing
### Preparatory actions
* Create SSH key to log on.
* Import the repository.
### Creating a remote server in DigitalOcean

##### Install the runtime package for the Ruby.
```
$ apt install ruby
```
##### Install the DropletKit client.
```
$ gem install droplet_kit
```
##### Run the script to create the server.
```
$ ruby create_droplet.rb
```
##### During the execution of the script, you will need to specify the Personal access tokens (generate on [site DigitalOcean](https://cloud.digitalocean.com/settings/api/tokens))
##### After creating the server, you need to connect to it using the ip address on the Dashboard DigitalOcean.
##### Connect to the server:
```
$ ssh ip_address
```
## Installing OpenVPN
##### Run script build openvpn system. All of the values should be populated automatically. Just press ENTER (in some cases "y") through the prompts to confirm the selections:
```
$ chmod +x openvpn.sh
$ ./openvpn.sh
```
##### Once you reach the stage of creating profiles, you will need to choose their number and measure of security.
### Transferring Configuration to Client Devices
##### Need to transfer the client configuration file to the relevant device. For instance, this could be your local computer or a mobile device. Run the command on the local device:
```
local$ sftp root@ip_address:client-configs/files/* ~/
```
### Usage
#### It remains only to download the OpenVPN for your platform and import the required profile.
## Installing SOCKS5 (dante-server)
```
$ chmod +x socks5.sh
$ ./socks5.sh
```
### Usage
#### Use the entered data (user & pass) to access the proxy server on port 1080 and ip address from Dashboard DigitalOcean.
