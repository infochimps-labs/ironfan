#!/usr/bin/env bash

# A url directory with the scripts you'd like to stuff into the machine
REMOTE_FILE_URL_BASE="http://github.com/mrflip/hadoop_cluster_chef/raw/master/config"

# Broaden the apt universe
if grep 'multiverse' /etc/apt/sources.list ; then true ; else
  sed -i 's/universe/multiverse universe/' /etc/apt/sources.list ;
  bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu karmic main restricted"     >> /etc/apt/sources.list ';
  bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu karmic universe multiverse" >> /etc/apt/sources.list ';
fi

# Update package index and update the basic system files to newest versions
apt-get -y update  ;
apt-get -y upgrade ;
apt-get -f install ;

# base packages
apt-get install -y ruby ruby1.8-dev libopenssl-ruby1.8 rubygems ri irb build-essential wget ssl-cert git-core zlib1g-dev libxml2-dev ;
# unchain rubygems from the tyrrany of ubuntu
gem install --no-rdoc --no-ri rubygems-update --version=1.3.6 ; /var/lib/gems/1.8/bin/update_rubygems; gem update --no-rdoc --no-ri --system ; gem --version ;

# install chef
gem install --no-rdoc --no-ri chef ;

# This patches the ec2-set-hostname script to use /etc/hostname (otherwise it
# crams the ec2-assigned hostname in there regardless)
cp /usr/bin/ec2-set-hostname /usr/bin/ec2-set-hostname.`date "+%Y%m%d%H"`.orig ;
wget -nv ${REMOTE_FILE_URL_BASE}/ec2-set-hostname_replacement.py -O /usr/bin/ec2-set-hostname ;
chmod a+x /usr/bin/ec2-set-hostname

# bootstrap chef from *client* scripts
wget -nv ${REMOTE_FILE_URL_BASE}/chef_bootstrap.rb -O /tmp/chef_bootstrap.rb ;
wget -nv ${REMOTE_FILE_URL_BASE}/chef_client.json  -O /tmp/chef_client.json ;
chef-solo -c /tmp/chef_bootstrap.rb -j /tmp/chef_client.json

# pull in the client scripts that make this machine speak to the chef server
cp /etc/chef/client.rb /etc/chef/client-orig.rb ;
wget -nv ${REMOTE_FILE_URL_BASE}/client.rb -O /etc/chef/client.rb ;

# cleanup
apt-get autoremove;
updatedb;

echo "User data script (generic chef client) complete: `date`"
