#!/usr/bin/env ruby
require 'droplet_kit'
require 'timeout'

puts ""
puts "-----------------------------------Server creation-----------------------------------"
puts ""
puts "Enter the Personal access tokens: "

token = gets

puts ""
puts "--------------------------------------------------------------------------------------"
puts ""
puts "What region should the server be located in?
          1.  Amsterdam        (Datacenter 2 - Curently not available)
          2.  Amsterdam        (Datacenter 3)
          3.  Bangalore
          4.  Frankfurt
          5.  London
          6.  New York         (Datacenter 1)
          7.  New York         (Datacenter 2 - Curently not available)
          8.  New York         (Datacenter 3)
          9.  San Francisco    (Datacenter 1 - Curently not available)
          10. San Francisco    (Datacenter 2)
          11. Singapore
          12. Toronto
       Please choose the number of your region: "

region = gets.chomp
case region
when "1"
  region = "ams2"
when "2"
   region = 'ams3'
when "3"
   region = 'blr1'
when "4"
   region = 'fra1'
when "5"
   region = 'lon1'
when "6"
   region = 'nyc1'
when "7"
   region = 'nyc2'
when "8"
   region = 'nyc3'
when "9"
   region = 'sfo1'
when "10"
   region = 'sfo2'
when "11"
   region = 'sgp1'
when "12"
   region = 'tor1'
else
   puts "Input was wrong"
end

puts ""
puts "--------------------------------------------------------------------------------------"
puts ""

client = DropletKit::Client.new(access_token: token)
pub_key = File.read(File.expand_path("~/.ssh/id_rsa.pub"))

ssh_key = DropletKit::SSHKey.new(
  name: 'My SSH Public Key',
  public_key: pub_key
)
client.ssh_keys.create(ssh_key)

my_ssh_keys = client.ssh_keys.all.collect {|key| key.fingerprint}
droplet = DropletKit::Droplet.new(
  name: 'shsyea',
  region: region,
  size: '512mb',
  image: 'ubuntu-16-04-x64',
  ssh_keys: my_ssh_keys
  )

puts "Exchanging ssh keys."
puts ""
puts "--------------------------------------------------------------------------------------"

client.droplets.create(droplet)

puts ""
puts "Server has been created!"
puts ""
puts "--------------------------------------------------------------------------------------"
puts ""
