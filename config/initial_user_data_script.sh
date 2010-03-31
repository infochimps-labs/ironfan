#!/usr/bin/env bash

# Broaden the apt universe
if grep 'multiverse' /etc/apt/sources.list ; then true ; else
  sudo sed -i 's/universe/multiverse universe/' /etc/apt/sources.list ;
  sudo bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu karmic main restricted"     >> /etc/apt/sources.list ';
  sudo bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu karmic universe multiverse" >> /etc/apt/sources.list ';
fi

# Update package index and update the basic system files to newest versions
sudo apt-get -y update  ;
sudo apt-get -y upgrade ;
sudo apt-get -f install ;

# base packages
sudo apt-get install -y ruby ruby1.8-dev libopenssl-ruby1.8 rubygems ri irb build-essential wget ssl-cert git-core zlib1g-dev libxml2-dev ;
# unchain rubygems from the tyrrany of ubuntu
sudo gem install --no-rdoc --no-ri rubygems-update --version=1.3.6 ; sudo /var/lib/gems/1.8/bin/update_rubygems; sudo gem update --no-rdoc --no-ri --system ; gem --version ;

# install chef
sudo gem install --no-rdoc --no-ri chef ;

REMOTE_FILE_URL_BASE="http://github.com/mrflip/chef-repo/raw/master"

# bootstrap chef from *client* scripts
wget ${REMOTE_FILE_URL_BASE}/config/chef_bootstrap.rb -O /tmp/chef_bootstrap.rb ;
wget ${REMOTE_FILE_URL_BASE}/config/chef_client.json  -O /tmp/chef_client.json ;
sudo chef-solo -c /tmp/chef_bootstrap.rb -j /tmp/chef_client.json

# pull in the chef server client script
sudo mv /etc/chef/client.rb /etc/chef/client-orig.rb ;
sudo wget ${REMOTE_FILE_URL_BASE}/config/client.rb -O /etc/chef/client.rb ;

# cleanup
sudo apt-get autoremove;
sudo updatedb;
