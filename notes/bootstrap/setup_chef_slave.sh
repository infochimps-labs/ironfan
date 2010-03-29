# Broaden the apt universe
sudo sed -i 's/universe/multiverse universe/' /etc/apt/sources.list
sudo bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu karmic main restricted"     >> /etc/apt/sources.list ';
sudo bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu karmic universe multiverse" >> /etc/apt/sources.list ';
sudo apt-get -y update  ;
sudo apt-get -y upgrade ;
sudo apt-get -f install ;


# base packages
sudo apt-get install -y ruby ruby1.8-dev libopenssl-ruby1.8 rubygems ri irb build-essential wget ssl-cert git-core zlib1g-dev libxml2-dev ;
# unchain rubygems from the tyrrany of ubuntu
sudo gem install --no-rdoc --no-ri rubygems-update --version=1.3.6 ; sudo /var/lib/gems/1.8/bin/update_rubygems; sudo gem update --no-rdoc --no-ri --system ; gem --version ;

# install chef and bootstrap it
sudo gem install --no-rdoc --no-ri chef ;

# pull in the validation key
sudo mkdir /etc/chef ; sudo scp flip@mrflip.dyndns.org:/tmp/validation.pem /etc/chef/validation.pem ; sudo chown root:root /etc/chef/validation.pem ; sudo chmod og-rwx /etc/chef/validation.pem

wget http://gist.github.com/raw/347431/2b48849607fa7aed7bc771c40e0cc79293e12dae/chef_bootstrap.rb -O /tmp/chef_bootstrap.rb
wget http://gist.github.com/raw/347431/be495e2e825a7f9083bc514300f6029ea933b7e7/chef_client.json  -O /tmp/chef_client.json
sudo chef-solo -c /tmp/chef_bootstrap.rb -j /tmp/chef_client.json


# cleanup
sudo apt-get autoremove; 
sudo updatedb;
